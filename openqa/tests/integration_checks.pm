package integration_checks;

# GLDE: проверка всех ключевых интеграций через serial-консоль:
#   - идентичность ОС (os-release, кодовое имя)
#   - Яндекс Браузер: пакет, альтернатива x-www-browser, mimeapps, отсутствие Firefox
#   - сертификаты Минцифры: файлы, системное хранилище, NSS
#   - Calamares: пакет, настройки, брендинг, polkit, ярлык
#   - Cinnamon / mint-meta
#   - правки visual-gl: PT-шрифты, обои, sysctl ФСТЭК, NTP РФ, swappiness-сервис
#   - репозитории: Linux Mint (gigi) и Яндекс

use strict;
use warnings;
use base 'basetest';
use testapi qw(type_string wait_serial record_info);

my @checks = (
    ['os-release',        q(grep -q 'GreenLinux Debian Edition' /usr/lib/os-release)],
    ['codename',          q(grep -q zelenodolsk /usr/lib/os-release)],
    ['lsb-release',       q(grep -q 'GreenLinux Debian Edition' /etc/lsb-release)],
    ['glde-version',      q(test -f /etc/glde-version)],
    ['yandex-installed',  q(dpkg-query -W -f'${Status}' yandex-browser-stable | grep -q 'ok installed')],
    ['yandex-alt',        q(test "$(update-alternatives --query x-www-browser | sed -n 's/^Value: //p')" = /usr/bin/yandex-browser-stable)],
    ['yandex-mime',       q(grep -q 'x-scheme-handler/https=yandex-browser' /etc/xdg/mimeapps.list)],
    ['yandex-repo',       q(grep -q repo.yandex.ru /etc/apt/sources.list.d/yandex-browser.list)],
    ['no-firefox',        q(sh -c '! dpkg-query -W firefox-esr >/dev/null 2>&1')],
    ['certs-files',       q(test $(ls /usr/local/share/ca-certificates/russian-trusted | wc -l) -eq 2)],
    ['certs-trust',       q(test $(grep -c russian /etc/ca-certificates.conf) -eq 2)],
    ['certs-nss',         q(certutil -L -d sql:/etc/pki/nssdb | grep -q 'Russian Trusted Root CA')],
    ['calamares',         q(dpkg-query -W -f'${Status}' calamares | grep -q 'ok installed')],
    ['calamares-settings',q(grep -q 'branding: glde' /etc/calamares/settings.conf)],
    ['calamares-unpackfs',q(grep -q 'filesystem.squashfs' /etc/calamares/modules/unpackfs.conf)],
    ['calamares-icon',    q(test -f /etc/skel/Desktop/glde-install.desktop)],
    ['polkit-live',       q(test -f /etc/polkit-1/localauthority/50-local.d/45-glde-live.pkla)],
    ['cinnamon',          q(dpkg-query -W -f'${Status}' cinnamon | grep -q 'ok installed')],
    ['mint-meta',         q(dpkg-query -W -f'${Status}' mint-meta-cinnamon | grep -q 'ok installed')],
    ['mint-repo',         q(grep -q packages.linuxmint.com /etc/apt/sources.list.d/linuxmint.list)],
    ['pt-fonts',          q(test $(find /usr/share/fonts/truetype/pt -name '*.ttf' | wc -l) -ge 20)],
    ['wallpapers',        q(test $(ls /usr/share/backgrounds/greenlinux | wc -l) -ge 13)],
    ['gschema-override',  q(grep -q 'backgrounds/greenlinux/default_background.jpg' /usr/share/glib-2.0/schemas/mint-artwork.gschema.override)],
    ['fastfetch',         q(command -v fastfetch >/dev/null)],
    ['swappiness-svc',    q(systemctl is-enabled glde-swappiness.service | grep -q enabled)],
    ['fstec-kptr',        q(test $(cat /proc/sys/kernel/kptr_restrict) -eq 2)],
    ['fstec-dmesg',       q(test $(cat /proc/sys/kernel/dmesg_restrict) -eq 1)],
    ['timesync-ru',       q(grep -q vniiftri /etc/systemd/timesyncd.conf.d/glde-ru.conf)],
    ['locale-ru',         q(grep -q 'ru_RU.UTF-8' /etc/default/locale)],
    ['lightdm-autologin', q(grep -q autologin-user=glde /etc/lightdm/lightdm.conf.d/70-glde-live-autologin.conf)],
    ['grub-theme',        q(grep -q 'GRUB_THEME=' /etc/default/grub.d/51_glde.cfg)],
);

sub run {
    my ($self) = @_;
    my @failures;

    record_info('checks', 'running ' . scalar(@checks) . ' integration checks via serial console');

    for my $check (@checks) {
        my ($name, $cmd) = @{$check};
        type_string('(' . $cmd . ') >/dev/null 2>&1; echo CHECK_' . $name . '=$?' . "\n");
        my $ok = wait_serial('CHECK_' . $name . '=0', timeout => 90, quiet => 1);
        if ($ok) {
            record_info($name, 'PASS');
            print "GLDE-CHECK $name: PASS\n";
        }
        else {
            record_info($name, 'FAIL');
            print "GLDE-CHECK $name: FAIL\n";
            push @failures, $name;
        }
    }

    # Дополнительно: версии ключевых компонентов в лог
    type_string("echo ===_versions===; grep PRETTY /usr/lib/os-release; dpkg-query -W yandex-browser-stable calamares cinnamon mint-meta-cinnamon 2>/dev/null; echo ===end===\n");
    wait_serial('===end===', timeout => 90);

    # Чистое выключение
    type_string("echo glde | sudo -S poweroff 2>/dev/null || true\n");

    if (@failures) {
        die 'GLDE integration checks FAILED: ' . join(', ', @failures) . "\n";
    }

    record_info('result', 'ALL integration checks passed');
    return;
}

sub test_flags {
    return {fatal => 1};
}

1;
