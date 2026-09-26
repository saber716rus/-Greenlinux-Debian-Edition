#!/bin/bash
# GLDE: локальная сборка ISO через Docker (как в CI).

set -euo pipefail

cd "$(dirname "$0")"

docker pull debian:trixie
docker run --privileged --rm \
  -v "$(pwd):/glde" -w /glde \
  -e DEBIAN_FRONTEND=noninteractive \
  debian:trixie \
  bash scripts/build-in-container.sh

echo ""
echo "Готово:"
ls -lh ./*.iso SHA256SUMS
