#!/usr/bin/env bash
# Mirror .github/workflows/ci.yml locally (Ubuntu apt: Verilator 5.020, Yosys).
# Prereqs (WSL/Ubuntu):  sudo apt-get install -y verilator g++ make yosys zlib1g-dev
# Usage:  cd sim && bash run_ci_local.sh
set -euo pipefail

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SIM_DIR/.." && pwd)"
cd "$SIM_DIR"

echo "==> Verilator: $(verilator --version | head -1)"

echo "==> RTL lint"
verilator --lint-only -Wall -Wno-fatal --sv \
    --top-module apb_slave_top \
    ../rtl/read_mux.sv ../rtl/apb_decoder.sv \
    ../rtl/register_bank.sv ../rtl/apb_response_logic.sv \
    ../rtl/apb_slave_top.sv

echo "==> Simulation regression"
bash run_sim.sh

echo "==> Wave capture (FST)"
bash run_wave.sh
test -f ../reports/wave/apb_wave.fst

echo "==> Yosys synthesis"
bash synth.sh
test -f ../reports/synth/synth_report.txt
grep -q "Number of cells" ../reports/synth/synth_report.txt

echo "==> ALL CI CHECKS PASSED"
