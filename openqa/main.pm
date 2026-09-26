use strict;
use warnings;
use testapi;
use autotest;

# GLDE openQA — планировщик тестов.
# Тесты безигольные (needle-free): проверки идут через serial-консоли
# (в bootappend-live ISO прописан console=ttyS0,115200; интерактивный
# терминал — virtio-console, см. lib/GLDE.pm).

use GLDE;
testapi::set_distribution(GLDE->new());

autotest::loadtest('tests/bootloader.pm');
autotest::loadtest('tests/boot_live.pm');
autotest::loadtest('tests/integration_checks.pm');

# Полный тест установки через Calamares требует снятия игл (needles)
# с реального экрана — включается переменной GLDE_INSTALL_TEST=1.
if (get_var('GLDE_INSTALL_TEST')) {
    autotest::loadtest('tests/install_calamares.pm');
}

1;
