#!/bin/bash
# GLDE: локальный запуск тестов через isotovideo (ядро os-autoinst/openQA)
# внутри Docker-контейнера openqa_worker. Не требует web-стека openQA.
#
# Использование:
#   ./run-isotovideo.sh /path/to/glde-*.iso [режим]
#
# Результаты: isotovideo-out/ (autoinst-log.txt, screenshots/, video.webm, ...)

set -euo pipefail

ISO="${1:?usage: run-isotovideo.sh <iso> [mode]}"
MODE="${2:-smoke}"
IMAGE="${GLDE_WORKER_IMAGE:-registry.opensuse.org/devel/openqa/containers16.0/openqa_worker}"

ISO="$(readlink -f "${ISO}")"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${HERE}/isotovideo-out"

echo "=== GLDE isotovideo runner ==="
echo "ISO:    ${ISO}"
echo "Mode:   ${MODE}"

mkdir -p "${OUT}"
rm -rf "${OUT:?}"/*

# Каталог прогона: main.pm + lib + tests + needles + vars.json
# (CASEDIR/NEEDLES_DIR — абсолютные пути ВНУТРИ контейнера)
cp -r "${HERE}/main.pm" "${HERE}/lib" "${HERE}/tests" "${HERE}/needles" "${OUT}/"

jq --arg iso "${ISO}" --arg test "${MODE}" \
   --arg casedir "/mnt/run" --arg needlesdir "/mnt/run/needles" \
   '.ISO = $iso | .TEST = $test | .CASEDIR = $casedir | .NEEDLES_DIR = $needlesdir' \
   "${HERE}/vars.json" > "${OUT}/vars.json"
cat "${OUT}/vars.json"

docker run --rm --privileged \
  -v "${OUT}:/mnt/run" -w /mnt/run \
  --entrypoint bash \
  "${IMAGE}" \
  -c "ls -la && isotovideo 2>&1 | tee -a console.log" || true

echo ""
echo "=== Результаты: ${OUT} ==="
ls -la "${OUT}"
echo ""
echo "--- GLDE-CHECK строки ---"
grep -a "GLDE-CHECK" "${OUT}/autoinst-log.txt" "${OUT}/console.log" 2>/dev/null || true
