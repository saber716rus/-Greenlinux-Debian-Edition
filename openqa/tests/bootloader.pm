package bootloader;

# GLDE: ожидание загрузчика GRUB.
# GRUB ISO не выводит меню в serial, поэтому грузимся по таймауту умолчанию.
# Здесь лишь фиксируем, что QEMU стартовал и передаём управление дальше.

use strict;
use warnings;
use base 'basetest';
use testapi qw(record_info sleep);

sub run {
    my ($self) = @_;
    record_info('bootloader', 'GRUB timeout boot in progress (default entry: live)');
    # GRUB_TIMEOUT ISO ~5s; даём запас и не мешаем авто-загрузке
    sleep 10;
    return;
}

sub test_flags {
    return {fatal => 1};
}

1;
