#!/usr/bin/env python3
"""
GLDE smoke-test: загрузка ISO в QEMU (BIOS и/или UEFI) с проверками через
serial-консоль (console=ttyS0 прописан в bootappend-live).

Проверяется:
  1. Загрузка ядра и live-boot
  2. Автологин-приглашение serial-getty
  3. Вход как glde/glde
  4. Интеграции: Яндекс Браузер (пакет + альтернативы), сертификаты Минцифры
     (хранилище + ca-certificates.conf), Calamares (пакет + настройки + брендинг),
     Cinnamon, mint-meta, os-release GLDE, PT-шрифты, обои, fastfetch.

Использование:
  python3 scripts/qemu-smoke-test.py <путь-к-ISO> [--mode bios|uefi|both] [--ram MB]
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import time

try:
    import pexpect
except ImportError:
    print("pexpect is required: pip install pexpect", file=sys.stderr)
    sys.exit(2)

LOGIN_PROMPT = re.compile(rb"login:")
BOOT_TIMEOUT = int(os.environ.get("GLDE_BOOT_TIMEOUT", "2700"))  # 45 min (TCG is slow)
CMD_TIMEOUT = int(os.environ.get("GLDE_CMD_TIMEOUT", "420"))
RAM_DEFAULT = 4096


class BootTest:
    def __init__(self, iso: str, mode: str, ram: int, workdir: str):
        self.iso = os.path.abspath(iso)
        self.mode = mode
        self.ram = ram
        self.workdir = workdir
        self.serial_log = os.path.join(workdir, f"serial-{mode}.log")
        self.results = []

    def qemu_cmd(self) -> list:
        cmd = [
            "qemu-system-x86_64",
            "-machine", "q35",
            "-accel", "tcg",
            "-cpu", "max",
            "-smp", "2",
            "-m", str(self.ram),
            "-display", "none",
            "-vga", "virtio",
            "-serial", "stdio",
            "-monitor", "none",
            "-net", "none",
            "-boot", "d",
        ]
        if self.mode == "uefi":
            ovmf = "/usr/share/ovmf/OVMF.fd"
            if not os.path.exists(ovmf):
                ovmf = "/usr/share/OVMF/OVMF_4M.fd"
            cmd += ["-bios", ovmf]
        cmd += ["-cdrom", self.iso]
        return cmd

    def record(self, name: str, ok: bool, detail: str = ""):
        self.results.append((name, ok, detail))
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))

    def run(self) -> bool:
        print(f"=== GLDE smoke test [{self.mode}] ===")
        print(f"ISO: {self.iso} ({os.path.getsize(self.iso) / 1e9:.2f} GB)")
        print(f"RAM: {self.ram} MB, boot timeout: {BOOT_TIMEOUT}s")

        cmd = self.qemu_cmd()
        print("CMD:", " ".join(cmd))

        with open(self.serial_log, "wb") as logf:
            child = pexpect.spawn(cmd[0], cmd[1:], timeout=BOOT_TIMEOUT,
                                  encoding=None, codec_errors="ignore")
            # Пишем всё в лог
            child.logfile_read = logf

            try:
                # 1) Ждём приглашение login (serial-getty@ttyS0)
                print("Waiting for login prompt (serial console)...")
                idx = child.expect([LOGIN_PROMPT, pexpect.EOF, pexpect.TIMEOUT])
                if idx != 0:
                    print("FATAL: no login prompt on serial console")
                    self.record("boot-to-login", False, "no login prompt")
                    # Диагностика: хвост serial-лога в вывод job
                    logf.flush()
                    try:
                        with open(self.serial_log, "rb") as f:
                            tail = f.read()[-2000:].decode(errors="ignore")
                        print("---- serial log tail ----")
                        print(tail)
                        print("---- end serial log tail ----")
                    except Exception:
                        pass
                    return False
                self.record("boot-to-login", True, "serial-getty login prompt reached")

                # 2) Логин
                child.sendline(b"glde")
                child.expect(re.compile(rb"Password:"), timeout=300)
                child.sendline(b"glde")
                child.expect(re.compile(rb"[#$] "), timeout=300)
                self.record("serial-login", True, "user glde logged in")

                # 3) Проверки
                checks = [
                    ("os-release", "grep 'GreenLinux Debian Edition' /usr/lib/os-release"),
                    ("hostname", "hostname"),
                    ("yandex-browser", "dpkg-query -W -f='${Status}\\n' yandex-browser-stable"),
                    ("yandex-default-alt", "update-alternatives --query x-www-browser | grep -c yandex || true"),
                    ("yandex-desktop", "ls /usr/share/applications/ | grep -c yandex-browser"),
                    ("no-firefox", "dpkg-query -W firefox-esr 2>/dev/null | grep -c 'ok installed' || echo 0"),
                    ("minifry-certs-files", "ls /usr/local/share/ca-certificates/russian-trusted/ | grep -c russian"),
                    ("minifry-certs-trust", "grep -c russian /etc/ca-certificates.conf || true"),
                    ("minifry-nss", "certutil -L -d sql:/etc/pki/nssdb 2>/dev/null | grep -c 'Russian Trusted' || true"),
                    ("calamares-pkg", "dpkg-query -W -f='${Status}\\n' calamares"),
                    ("calamares-settings", "grep -c 'branding: glde' /etc/calamares/settings.conf"),
                    ("calamares-unpackfs", "grep -c 'filesystem.squashfs' /etc/calamares/modules/unpackfs.conf"),
                    ("calamares-icon", "ls /etc/skel/Desktop/glde-install.desktop"),
                    ("cinnamon", "dpkg-query -W -f='${Status}\\n' cinnamon"),
                    ("mint-meta", "dpkg-query -W -f='${Status}\\n' mint-meta-cinnamon"),
                    ("pt-fonts", "find /usr/share/fonts/truetype/pt -name '*.ttf' | wc -l"),
                    ("wallpapers", "ls /usr/share/backgrounds/greenlinux/ | wc -l"),
                    ("fastfetch", "command -v fastfetch"),
                    ("swappiness-svc", "systemctl is-enabled glde-swappiness.service || true"),
                    ("fstec-sysctl", "cat /proc/sys/kernel/kptr_restrict"),
                    ("timesync-ru", "grep -c vniiftri /etc/systemd/timesyncd.conf.d/glde-ru.conf || true"),
                ]

                for name, command in checks:
                    marker = f"__CHK_{name}__"
                    child.sendline(f"echo {marker}$( {command} 2>/dev/null | tr '\\n' '|' )".encode())
                    try:
                        child.expect(re.compile((marker + "(.*)\\r").encode()), timeout=CMD_TIMEOUT)
                        out = child.match.group(1).decode(errors="ignore").strip()
                    except (pexpect.TIMEOUT, pexpect.EOF):
                        out = "<timeout>"
                    ok = out != "<timeout>" and out != ""
                    if name in ("no-firefox",):
                        ok = out.strip("|") == "0"
                    if name == "yandex-default-alt":
                        ok = out.strip("|") not in ("0", "")
                    if name == "minifry-certs-files":
                        ok = out.strip("|") == "2"
                    if name == "minifry-certs-trust":
                        ok = out.strip("|") == "2"
                    if name in ("os-release", "yandex-browser", "calamares-pkg", "cinnamon", "mint-meta"):
                        ok = "install ok installed" in out or "GreenLinux" in out
                    if name == "calamares-settings":
                        ok = out.strip("|") == "1"
                    if name == "calamares-unpackfs":
                        ok = out.strip("|") == "1"
                    if name == "pt-fonts":
                        ok = out.strip("|").isdigit() and int(out.strip("|")) >= 20
                    if name == "wallpapers":
                        ok = out.strip("|").isdigit() and int(out.strip("|")) >= 13
                    if name == "fstec-sysctl":
                        ok = out.strip("|") == "2"
                    if name == "swappiness-svc":
                        ok = "enabled" in out
                    self.record(name, ok, out[:120])

                # 4) Корректное выключение
                child.sendline(b"echo glde | sudo -S poweroff 2>/dev/null || true")
                try:
                    child.expect(pexpect.EOF, timeout=240)
                except (pexpect.TIMEOUT, pexpect.EOF):
                    child.terminate(force=True)
            finally:
                child.terminate(force=True)

        return all(ok for _, ok, _ in self.results)

    def report(self) -> str:
        lines = [f"=== GLDE smoke test report [{self.mode}] ==="]
        for name, ok, detail in self.results:
            lines.append(f"{'PASS' if ok else 'FAIL'}\t{name}\t{detail}")
        lines.append(f"TOTAL: {sum(1 for _, ok, _ in self.results if ok)}/{len(self.results)} passed")
        return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("iso")
    ap.add_argument("--mode", default="both", choices=["bios", "uefi", "both"])
    ap.add_argument("--ram", type=int, default=RAM_DEFAULT)
    args = ap.parse_args()

    if not os.path.exists(args.iso):
        print(f"ISO not found: {args.iso}", file=sys.stderr)
        sys.exit(2)

    if shutil.which("qemu-system-x86_64") is None:
        print("qemu-system-x86_64 not found", file=sys.stderr)
        sys.exit(2)

    workdir = os.environ.get("GLDE_TEST_WORKDIR", os.path.abspath("smoke-test-out"))
    os.makedirs(workdir, exist_ok=True)

    modes = ["bios", "uefi"] if args.mode == "both" else [args.mode]
    overall = True
    for mode in modes:
        if mode == "uefi":
            # OVMF может отсутствовать — пропускаем с предупреждением
            has_ovmf = any(os.path.exists(p) for p in
                           ["/usr/share/ovmf/OVMF.fd", "/usr/share/OVMF/OVMF_4M.fd",
                            "/usr/share/OVMF/OVMF_CODE_4M.fd"])
            if not has_ovmf:
                print("WARNING: OVMF firmware not found, skipping UEFI test")
                continue
        bt = BootTest(args.iso, mode, args.ram, workdir)
        ok = bt.run()
        print(bt.report())
        with open(os.path.join(workdir, f"report-{mode}.txt"), "w") as f:
            f.write(bt.report() + "\n")
        overall = overall and ok

    print("=== SMOKE TEST", "PASSED" if overall else "FAILED", "===")
    sys.exit(0 if overall else 1)


if __name__ == "__main__":
    main()
