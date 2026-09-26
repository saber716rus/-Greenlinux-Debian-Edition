# openQA / os-autoinst — тесты GLDE

Тестовый дистрибутив (`DISTRI=glde`) для openQA и isotovideo.

## Структура

```
main.pm                 # планировщик: bootloader → boot_live → integration_checks
lib/distribution.pm     # класс дистрибутива
tests/bootloader.pm     # ожидание GRUB (авто-загрузка по таймауту)
tests/boot_live.pm      # загрузка до serial-getty + вход glde/glde
tests/integration_checks.pm  # ~30 проверок всех интеграций GLDE
tests/install_calamares.pm   # расширенный трек установки (нужны иглы)
vars.json               # переменные прогона isotovideo
templates               # шаблоны заданий для web-UI openQA
docker-compose.yml      # полный стек openQA (db + webui + worker)
run-isotovideo.sh       # локальный запуск через isotovideo в контейнере
```

## Запуск

### isotovideo (ядро openQA, без web-стека)

```bash
./run-isotovideo.sh ../glde-09.2026-draft-amd64.iso smoke
```

Результаты — в `isotovideo-out/`: `autoinst-log.txt` (полный лог,
строки `GLDE-CHECK <имя>: PASS|FAIL`), `video.webm`, `screenshots/`.

### Полный openQA в контейнерах

```bash
docker compose up -d          # web-UI: http://127.0.0.1:9527
# затем задание через UI/CLI (см. openqa.yml → job openqa-full)
```

### В GitHub Actions

Workflow `.github/workflows/openqa.yml`:
- job **isotovideo** — запускается автоматически после build (и вручную);
- job **openqa-full** — полный стек, опция `run_full_stack`.

## Почему проверки без игл (needle-free)

ISO собран с `console=ttyS0,115200` в параметрах ядра — serial-консоль
даёт детерминированный текстовый канал проверок в CI без привязки к
пиксельным скриншотам. Это делает прогоны стабильными на TCG (GitHub-раннеры
без KVM) и позволяет верифицировать все интеграции (Яндекс Браузер, сертификаты
Минцифры, Calamares, правки visual-gl) на каждом коммите.

## Съёмка игл для теста установки (install_calamares)

1. Соберите ISO и запустите его в openQA с `GLDE_INSTALL_TEST=1` — тест
   остановится с сообщением об отсутствии игл.
2. Откройте web-UI → задание → редактор игл (needle editor), снимите
   скриншоты ключевых экранов Calamares (welcome, locale, keyboard,
   partition, users, summary, progress, finished) и создайте
   `needles/calamares-*.json`.
3. Доработайте навигацию в `tests/install_calamares.pm`
   (`assert_screen` + `send_key`/`type_string`) по снятым экранам.
4. Повторный прогон выполнит полный цикл установки.
