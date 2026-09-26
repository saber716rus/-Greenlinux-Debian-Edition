package GLDE;

# GLDE openQA — класс дистрибутива.
# Регистрирует virtio-terminal (ввод/вывод через virtio-console QEMU,
# как root-virtio-terminal в os-autoinst-distri-opensuse).
# В госте порт org.openqa.console.virtio_console обслуживается юнитом
# glde-virtio-shell@.service (bash с промптом GLDE-SHELL>).
# Вывод ядра (console=ttyS0 в ISO) читается через wait_serial напрямую.

use strict;
use warnings;
use base 'distribution';

sub init {
    my ($self) = @_;
    $self->SUPER::init();
    $self->add_console('root-virtio-terminal', 'virtio-terminal', {});
    return;
}

1;
