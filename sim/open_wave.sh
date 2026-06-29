#!/usr/bin/env bash
# Open apb_wave.fst in GTKWave (MSYS2 MINGW64)
set -euo pipefail

export PATH=/mingw64/bin:/usr/bin:$PATH

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAVE_DIR="$ROOT/reports/wave"
FST="$WAVE_DIR/apb_wave.fst"

if [[ ! -f "$FST" ]]; then
    echo "FST not found: $FST"
    echo "Generate it first:  cd sim && make wave"
    exit 1
fi

if ! command -v gtkwave >/dev/null 2>&1; then
    echo "GTKWave not found on PATH."
    echo ""
    echo "Install in MSYS2 MINGW64:"
    echo "  pacman -S mingw-w64-x86_64-gtkwave"
    echo ""
    echo "Then open a NEW MINGW64 shell and run:"
    echo "  cd sim && make wave-view"
    exit 1
fi

echo "Opening: $FST"
cd "$WAVE_DIR"

# Open FST directly (most reliable; avoids broken .gtkw signal paths)
if [[ -f apb_wave.tcl ]]; then
    gtkwave apb_wave.fst apb_wave.tcl &
else
    gtkwave apb_wave.fst &
fi

echo "GTKWave started. Add signals from the SST tree:"
echo "  tb_apb_wave.vif.psel, .penable, .pwrite, .paddr, .pwdata, .prdata, .pready, .pslverr"
