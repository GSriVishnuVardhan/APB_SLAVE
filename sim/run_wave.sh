#!/usr/bin/env bash
# Short traced simulation for GTKWave (minimal TB — avoids full-regression trace bug)
set -euo pipefail

export PATH=/mingw64/bin:/usr/bin:$PATH

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SIM_DIR/.." && pwd)"
cd "$SIM_DIR"

TOP="tb_apb_wave"
OUT="obj_wave/V${TOP}"
WAVE_DIR="$ROOT/reports/wave"
mkdir -p "$WAVE_DIR" obj_wave

RTL="$ROOT/rtl/read_mux.sv $ROOT/rtl/apb_decoder.sv $ROOT/rtl/register_bank.sv \
     $ROOT/rtl/apb_response_logic.sv $ROOT/rtl/apb_slave_top.sv"
TB="$ROOT/tb/apb_if.sv $ROOT/tb/apb_driver.sv $ROOT/tb/tb_apb_wave.sv"

echo "==> Clean"
rm -rf obj_wave
mkdir -p obj_wave

echo "==> Verilator compile (FST trace)"
verilator --cc --timing -Wall -Wno-fatal --sv \
    --trace-fst --trace-structs \
    --top-module "$TOP" \
    -Mdir obj_wave \
    --exe "$SIM_DIR/wave_main.cpp" \
    --build -j 0 \
    $RTL $TB

echo "==> Run wave capture"
(
    cd obj_wave
    if [[ -f Vtb_apb_wave.exe ]]; then
        ./Vtb_apb_wave.exe 2>/dev/null || MSYS2_ARG_CONV_EXCL='*' cmd.exe //c Vtb_apb_wave.exe
    else
        ./Vtb_apb_wave
    fi
)
cd "$SIM_DIR"

FST="obj_wave/apb_wave.fst"
if [[ -f "$FST" ]]; then
    cp -f "$FST" "$WAVE_DIR/apb_wave.fst"
    echo "==> FST: $WAVE_DIR/apb_wave.fst ($(wc -c < "$FST") bytes)"
elif [[ -f "obj_wave/V${TOP}.fst" ]]; then
    cp -f "obj_wave/V${TOP}.fst" "$WAVE_DIR/apb_wave.fst"
    echo "==> FST: $WAVE_DIR/apb_wave.fst"
else
    echo "WARNING: FST not found in obj_wave/ — check trace flags"
fi

cp -f "$ROOT/reports/wave/apb_wave.tcl" "$WAVE_DIR/apb_wave.tcl" 2>/dev/null || true

echo "==> GTKWave: cd sim && make wave-view"
echo "    (or: cd reports/wave && gtkwave apb_wave.fst apb_wave.tcl)"
echo "==> Done"
