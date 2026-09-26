#!/bin/bash
# GLDE: сборка ISO внутри Docker-контейнера Debian trixie (запускается
# из GitHub Actions через `docker run --privileged`).
#
# Использование: docker run --privileged --rm -v "$PWD:/glde" -w /glde \
#                    debian:trixie bash scripts/build-in-container.sh

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

echo "=== GLDE build: container environment ==="
cat /etc/os-release | head -2
nproc
df -h / | tail -1

echo "=== Installing build tools ==="
apt-get update
apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    xorriso \
    squashfs-tools \
    wget \
    ca-certificates \
    file \
    git

lb --version

echo "=== lb config (auto/config) ==="
lb config

echo "=== lb build ==="
# Логи пишем и в файл, и в stdout; tee не глотает код ошибки lb build.
set -o pipefail
lb build 2>&1 | tee /glde/build.log
BUILD_RC=${PIPESTATUS[0]}
set +o pipefail

if [ "${BUILD_RC}" -ne 0 ]; then
    echo "=== BUILD FAILED (rc=${BUILD_RC}) ==="
    tail -100 /glde/build.log || true
    exit "${BUILD_RC}"
fi

echo "=== Build artifacts ==="
ls -lh /glde/*.iso || true

# Контрольные суммы
cd /glde
if ls *.iso >/dev/null 2>&1; then
    sha256sum *.iso > SHA256SUMS
    cat SHA256SUMS
else
    echo "FATAL: no ISO produced" >&2
    exit 1
fi

echo "=== GLDE build: SUCCESS ==="
