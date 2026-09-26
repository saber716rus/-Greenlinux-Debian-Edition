package boot_live;

# GLDE: загрузка live-системы до приглашения serial-getty и вход пользователем.
# Умолчания live-сессии (bootappend-live ISO):
#   username=glde  user-password=glde  hostname=glde-live  console=ttyS0,115200

use strict;
use warnings;
use base 'basetest';
use testapi qw(select_console wait_serial type_string record_info);

sub run {
    my ($self) = @_;
    my $boot_timeout = get_var('GLDE_BOOT_TIMEOUT', 1800);

    record_info('boot', "waiting up to ${boot_timeout}s for serial login prompt");

    my $matched = wait_serial('login:', timeout => $boot_timeout);
    unless ($matched) {
        die 'GLDE: login prompt did not appear on serial console (boot failure?)';
    }

    select_console('serial-console');

    type_string("glde\n");
    unless (wait_serial('Password:', timeout => 180)) {
        die 'GLDE: no Password prompt on serial console';
    }
    type_string("glde\n");
    unless (wait_serial('glde@', timeout => 180)) {
        die 'GLDE: serial login as glde failed';
    }

    # Облегчаем вывод: без цвета и с коротким приглашением
    type_string("export PS1='GLDE> '\n");
    wait_serial('GLDE>', timeout => 60);

    record_info('login', 'serial login OK (user glde)');
    return;
}

sub test_flags {
    return {fatal => 1};
}

1;
