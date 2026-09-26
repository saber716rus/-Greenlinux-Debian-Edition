# Иглы (needles) GLDE

Иглы openQA создаются из реальных скриншотов запущенного образа:

1. Запустите тест (isotovideo или openQA web-UI) — скриншоты сохраняются
   в `isotovideo-out/screenshots/` (или в testresults задания).
2. Откройте web-UI → needle editor (или используйте `openqa-save-needle`),
   выделите область и сохраните `needles/<имя>.json` + `<имя>.png`.
3. Добавьте `assert_screen('<имя>', ...)` в тесты.

Текущие тесты (smoke) needle-free — все проверки через serial-консоль.
Иглы понадобятся для `tests/install_calamares.pm` (полный тест установки).
