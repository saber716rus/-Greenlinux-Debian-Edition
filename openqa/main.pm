use strict;
use warnings;
use autotest;
use testapi;

# GLDE openQA — планировщик тестов.
# Тесты безигольные (needle-free): все проверки идут через serial-консоль
# (в bootappend-live ISO прописан console=ttyS0,115200).

autotest::loadtest('tests/bootloader.pm');
autotest::loadtest('tests/boot_live.pm');
autotest::loadtest('tests/integration_checks.pm');

# Полный тест установки через Calamares требует снятия игл (needles)
# с реального экрана — включается переменной GLDE_INSTALL_TEST=1.
if (get_var('GLDE_INSTALL_TEST')) {
    autotest::loadtest('tests/install_calamares.pm');
}

1;
