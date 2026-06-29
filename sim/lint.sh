#!/usr/bin/env bash
# Verilator lint-only on RTL (no testbench)
set -euo pipefail

export PATH=/mingw64/bin:/usr/bin:$PATH

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SIM_DIR/.." && pwd)"
cd "$SIM_DIR"

RTL="$ROOT/rtl/read_mux.sv \
     $ROOT/rtl/apb_decoder.sv \
     $ROOT/rtl/register_bank.sv \
     $ROOT/rtl/apb_response_logic.sv \
     $ROOT/rtl/apb_slave_top.sv"

echo "==> Verilator lint (RTL only)"
verilator --lint-only -Wall -Wno-fatal --sv \
    --top-module apb_slave_top \
    $RTL

echo "==> Lint PASS — no errors reported"
