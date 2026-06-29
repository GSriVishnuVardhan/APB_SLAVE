#!/usr/bin/env bash
# Run wave capture + Yosys synthesis inside Docker (Linux tools, reproducible).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${DOCKER_IMAGE:-ubuntu:24.04}"

echo "==> Docker image: $IMAGE"
docker run --rm \
    -v "$ROOT:/work" \
    -w /work/sim \
    "$IMAGE" \
    bash -lc '
        set -euo pipefail
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq verilator yosys gtkwave xvfb > /dev/null

        echo "==> Wave capture (Verilator + FST)"
        bash run_wave.sh

        echo "==> Yosys synthesis"
        bash synth.sh

        if [[ -f ../reports/wave/apb_wave.fst ]]; then
            echo "==> FST size: $(wc -c < ../reports/wave/apb_wave.fst) bytes"
        fi

        if command -v xvfb-run >/dev/null && [[ -f ../reports/wave/apb_wave.gtkw ]]; then
            echo "==> GTKWave PNG export (headless)"
            mkdir -p ../docs/images/gtkwave
            cd ../reports/wave
            xvfb-run -a gtkwave -o ../../docs/images/gtkwave/apb_wave.png apb_wave.gtkw 2>/dev/null || \
                echo "GTKWave PNG export skipped (CLI export not supported in this build)"
        fi
    '

echo "==> Docker checks complete"
