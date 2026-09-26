package distribution;

# GLDE openQA — класс дистрибутива.
# Serial-консоль (serial-console) регистрируется автоматически QEMU-бэкендом
# os-autoinst благодаря console=ttyS0 в параметрах ядра ISO.

use strict;
use warnings;
use base 'distribution';

sub init {
    my ($self) = @_;
    $self->SUPER::init();
    return;
}

1;
