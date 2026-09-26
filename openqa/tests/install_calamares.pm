package install_calamares;

# GLDE: полный тест установки через Calamares (расширенный трек).
#
# ВНИМАНИЕ: интерактивный тест установки требует игл (needles) со скриншотами
# реальных экранов Calamares GLDE. Иглы снимаются с реального образа:
#   1) запустите образ в openQA с GLDE_INSTALL_TEST=1 (needles будут отсутствовать)
#   2) снимите скриншоты в ключевых точках и создайте needles/*.json+png
#      (openqa-save-needle / редактор игл в web-интерфейсе)
#   3) повторите прогон
#
# Скелет теста реализует логику прохождения установщика и активируется
# только при наличии игл (GLDE_INSTALL_TEST=1 + файл needles/calamares-welcome.json).

use strict;
use warnings;
use base 'basetest';
use testapi qw(check_screen send_key type_string assert_screen get_var record_info);

sub run {
    my ($self) = @_;

    unless (get_var('GLDE_INSTALL_TEST')) {
        record_info('skip', 'install test disabled (set GLDE_INSTALL_TEST=1 to enable)');
        return;
    }

    unless (-f 'needles/calamares-welcome.json') {
        die 'GLDE: Calamares needles are not captured yet — '
          . 'see openqa/README.md (section "Съёмка игл"). '
          . 'Test cannot proceed without real screenshots.';
    }

    # Запуск установщика из live-сессии (через VNC-консоль)
    select_console('x11') if 0;    # serial-сессия уже установлена; для GUI-теста
                                   # нужен полноценный VNC-прогон с иглами

    assert_screen('calamares-welcome', 300);
    # ... навигация по шагам: locale, keyboard, partition, users, summary
    # (реализуется по мере снятия игл)
    die 'GLDE: install_calamares flow is not fully implemented yet (needles required)';
}

1;
