# Green Linux — Debian Edition (GLDE)

**Версия:** `GLDE.09.2026 (draft)` — версия разработчика (не альфа)
**Кодовое имя:** Зеленодольск
**База:** Debian 13 "trixie" (та же база, что у LMDE 7 "Gigi") + репозиторий Linux Mint
**Рабочий стол:** Cinnamon 6.4
**Браузер:** Яндекс Браузер — основной (Firefox удаляется)
**Сертификаты:** Минцифры — Russian Trusted Root CA / Sub CA
**Установщик:** Calamares (кастомный брендинг GLDE)

Сборка образа — Debian live-build в GitHub Actions (CI/CD + авто-релизы).
Форк [Green Linux](https://gitlab.linuxmint.su/greenlinux/visual-gl) на LMDE-базе со всеми правками visual-gl.

---

## Состав репозитория

```
auto/                      # live-build: скрипты конфигурации сборки
  config                   #   lb config — все параметры сборки (триxie, live, ISO)
  build                    #   lb build
  clean                    #   lb clean
config/
  archives/                # apt-репозитории: Linux Mint (gigi) + Яндекс Браузер (+ключи)
  package-lists/           # списки пакетов (live, mint, desktop, browser, calamares, apps, firmware)
  hooks/normal/            # chroot-хуки: идентичность, Минцифры, Яндекс, Calamares,
                           #   брендинг, сервисы, live-сессия, очистка
  hooks/live/              # binary-хук: брендинг ISO
  includes.chroot/         # файлы в образ: calamares/*, skel, обои, PT-шрифты, сертификаты,
                           #   sysctl ФСТЭК, NTP РФ, lightdm, polkit и т.д.
.github/workflows/         # CI/CD: build.yml, release.yml, smoke-test.yml, openqa.yml
scripts/                   # build-in-container.sh, qemu-smoke-test.py
openqa/                    # openQA/os-autoinst: тесты дистрибутива GLDE
build.sh                   # локальная сборка (Docker)
```

## Интеграции

| Компонент | Реализация |
|---|---|
| **Яндекс Браузер** | apt-репозиторий `repo.yandex.ru` (ключ в `config/archives/`); пакет `yandex-browser-stable`; альтернативы `x-www-browser`/`gnome-www-browser`; `/etc/xdg/mimeapps.list` + skel; Firefox вычищается |
| **Сертификаты Минцифры** | PEM из [gu-st.ru](https://gu-st.ru/content/lending/russian_trusted_root_ca_pem.crt) → `update-ca-certificates`; NSS `/etc/pki/nssdb` + `/etc/skel/.pki/nssdb` (Яндекс Браузер/Chromium); политика Firefox `ImportEnterpriseRoots` |
| **Calamares** | пакет `calamares` + собственные настройки `etc/calamares` (брендинг `glde`, русский, GRUB, lightdm); polkit для live-пользователя; ярлык «Установить Green Linux DE»; `unpackfs` из squashfs live-образа |
| **Правки visual-gl** | обои `backgrounds/greenlinux` + XML для Cinnamon; `mint-artwork.gschema.override` (Mint-Y-Dark); PT-шрифты (Astra Sans, Root UI, PT Sans/Mono/Serif); sysctl ФСТЭК (`kptr_restrict`, `dmesg_restrict`, `bpf_jit_harden`, `mmap_min_addr`); NTP-серверы РФ; адаптивный `vm.swappiness` (сервис); GRUB `init_on_alloc=1 slab_nomerge`; Intel Xorg; numlockx; логотип fastfetch; GUI обновления green-update |
| **LMDE-база** | Debian 13 + `packages.linuxmint.com` (gigi): `mint-meta-cinnamon`, `mint-artwork`, `mint-themes`, `mintinstall`, `mintupdate`, `mintsources`, `grub2-theme-mint`, `debian-system-adjustments`, plymouth `mint-logo` |

## CI/CD (GitHub Actions)

| Workflow | Триггер | Что делает |
|---|---|---|
| **build** | push в `main`, PR | Сборка ISO в контейнере `debian:trixie` (`lb config && lb build`), артефакт `glde-iso` (ISO + SHA256SUMS + build.log) |
| **release** | тег `v*` / вручную | Сборка ISO → автоматический **GitHub Release** (pre-release) с ISO, суммой и логом |
| **smoke-test** | после build / вручную | Загрузка ISO в QEMU (BIOS + UEFI, TCG), вход через serial-консоль, ~25 проверок интеграций |
| **openqa** | после build / вручную | Тесты через **os-autoinst/openQA**: job `isotovideo` (движок openQA в контейнере openqa-worker) + опционально полный стек openQA (webui+db+worker, опция `run_full_stack`) |

### Авто-релиз

```bash
git tag v0.9.2026-dev.1 && git push origin v0.9.2026-dev.1
```

Workflow `release` соберёт образ и опубликует релиз (как pre-release — GLDE.09.2026 это draft) с SHA256 и списком пакетов.

## Локальная сборка

Требуется Docker:

```bash
./build.sh                # = docker run --privileged debian:trixie + lb build
```

Итог: `glde-09.2026-draft-amd64.iso` + `SHA256SUMS`.

Live-сессия: пользователь `glde`, пароль `glde` (автологин в lightdm).

## Локальное тестирование (openQA)

```bash
# ядро os-autoinst (isotovideo) в контейнере openqa-worker:
./openqa/run-isotovideo.sh glde-09.2026-draft-amd64.iso smoke

# полный openQA (web-UI на http://127.0.0.1:9527):
cd openqa && docker compose up -d
```

Результаты: `openqa/isotovideo-out/` (autoinst-log.txt, video, screenshots).

Тесты дистрибутива (`openqa/tests/`) — needle-free: все проверки выполняются через
serial-консоль (в ISO прописан `console=ttyS0,115200`). Полный интерактивный тест
установки Calamares потребует снятия игл — см. `openqa/README.md`.

## Проверка сертификатов Минцифры в готовой системе

```bash
ls /usr/local/share/ca-certificates/russian-trusted/
grep russian /etc/ca-certificates.conf
certutil -L -d sql:/etc/pki/nssdb
```

## Источники

- Green Linux (visual): https://gitlab.linuxmint.su/greenlinux/visual-gl
- Green Linux: https://greenlinux.ru/ — форум: https://forum.linuxmint.su/
- LMDE: https://linuxmint.com/download_lmde.php
- live-build: https://live-team.pages.debian.net/live-manual/
- Calamares: https://calamares.io/
- openQA: https://github.com/os-autoinst/openQA
- Сертификаты: https://www.gosuslugi.ru/tls (gu-st.ru)
