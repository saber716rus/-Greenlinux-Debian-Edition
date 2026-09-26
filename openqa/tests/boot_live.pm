package boot_live;

# GLDE: загрузка live-системы и подготовка serial-терминала.
#
# Механика os-autoinst:
#  - вывод ядра: console=ttyS0 (в ISO) -> ringbuf -> wait_serial работает сразу
#  - интерактивный ввод: virtio-terminal (root-virtio-terminal);
#    в госте на порту org.openqa.console.virtio_console юнит
#    glde-virtio-shell@.service поднимает bash с промптом GLDE-SHELL>

use strict;
use warnings;
use base 'basetest';
use testapi qw(select_console wait_serial type_string record_info);

sub run {
    my ($self) = @_;
    my $boot_timeout = get_var('GLDE_BOOT_TIMEOUT', 1800);

    # 1) Ждём завершения загрузки по ttyS0 (serial-getty от systemd-getty-generator,
    #    т.к. в cmdline ядра прописан console=ttyS0)
    record_info('boot', "waiting up to ${boot_timeout}s for serial login prompt");
    my $booted = wait_serial('login:', timeout => $boot_timeout);
    unless ($booted) {
        die 'GLDE: login prompt did not appear on serial console (boot failure?)';
    }
    record_info('boot', 'system booted, serial-getty present');

    # 2) Переключаемся на virtio-terminal и ждём shell гостя
    select_console('root-virtio-terminal');

    # «Подталкиваем» промпт (см. serial_terminal::login в os-autoinst-distri-opensuse)
    type_string("\n");
    my $shell = wait_serial('GLDE-SHELL>', timeout => 300, quiet => 1);
    if (!$shell) {
        # Фолбэк: возможно getty на порту (hvc) с приглашением login
        type_string("\n");
        my $login = wait_serial('login:', timeout => 60, quiet => 1);
        if ($login) {
            type_string("glde\n");
            wait_serial('Password:', timeout => 120) || die 'GLDE: no Password prompt on virtio terminal';
            type_string("glde\n");
            wait_serial('glde@', timeout => 120) || die 'GLDE: login on virtio terminal failed';
            type_string("export PS1='GLDE-SHELL> '\n");
            wait_serial('GLDE-SHELL>', timeout => 60) || die 'GLDE: no prompt after login';
        }
        else {
            die 'GLDE: neither GLDE-SHELL> nor login prompt on virtio terminal';
        }
    }

    record_info('terminal', 'interactive shell on virtio terminal ready');
    return;
}

sub test_flags {
    return {fatal => 1};
}

1;
