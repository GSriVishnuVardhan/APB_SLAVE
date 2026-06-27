#!/usr/bin/env bash
# Compile and run APB slave TB with Verilator (MSYS2 MINGW64)
set -euo pipefail

export PATH=/mingw64/bin:/usr/bin:$PATH

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SIM_DIR/.." && pwd)"
cd "$SIM_DIR"

TOP="tb_apb_slave"
OUT="obj_dir/V${TOP}"
REPORT_DIR="$ROOT/reports"
mkdir -p "$REPORT_DIR"

RTL="$ROOT/rtl/apb_decoder.sv $ROOT/rtl/register_bank.sv $ROOT/rtl/apb_resp.sv $ROOT/rtl/apb_slave_top.sv"
TB="$ROOT/tb/apb_if.sv $ROOT/tb/apb_transaction.sv $ROOT/tb/apb_driver.sv $ROOT/tb/apb_monitor.sv \
    $ROOT/tb/apb_scoreboard.sv $ROOT/tb/apb_coverage.sv $ROOT/tb/apb_protocol_checker.sv $ROOT/tb/tb_apb_slave.sv"

echo "==> Clean"
rm -rf obj_dir

echo "==> Verilator compile"
verilator --timing --binary -Wall -Wno-fatal --sv \
    --top-module "$TOP" \
    -Mdir obj_dir \
    -o "V${TOP}" \
    $RTL $TB

echo "==> Run simulation"
"$OUT" | tee "$REPORT_DIR/sim.log"

echo "==> Reports in $REPORT_DIR"
ls -la "$REPORT_DIR"/coverage_summary.txt "$REPORT_DIR"/regression_report.txt 2>/dev/null || true

echo "==> Done"
