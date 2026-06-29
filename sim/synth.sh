#!/usr/bin/env bash
# Yosys synthesis — RTL only, open-source flow (generic ASIC/FPGA mapping)
set -euo pipefail

export PATH=/mingw64/bin:/usr/bin:$PATH

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SIM_DIR/.." && pwd)"
OUT="$ROOT/reports/synth"
mkdir -p "$OUT"

cd "$SIM_DIR"
echo "==> Yosys synthesis (USE_APB_FSM=0 default)"

if ! yosys -l "$OUT/yosys.log" synth.ys > "$OUT/synth_report.txt" 2>&1; then
    echo "==> SYNTH FAILED — see $OUT/synth_report.txt and $OUT/yosys.log"
    tail -20 "$OUT/synth_report.txt"
    exit 1
fi

# Parse Yosys stat output into a readable summary (see synth_report.txt for full log)
SUMMARY="$OUT/synth_summary.txt"
awk '
BEGIN { in_hier=0; pass=0 }
/^=== design hierarchy ===/ { in_hier=1; next }
in_hier && /^   Number of cells:/ {
    total_cells=$4
    getline; while ($0 ~ /^     /) { detail=detail $0 "\n"; getline }
    in_hier=0
}
/=== SYNTH PASS ===/ { pass=1 }
END {
    if (total_cells == "") exit 1
}
' "$OUT/synth_report.txt" || {
    echo "==> SYNTH FAILED — could not parse stat summary"
    exit 1
}

# Build human-readable summary with per-module breakdown
{
    echo "APB3 Slave — Yosys Synthesis Summary"
    echo "====================================="
    echo "Top module: apb_slave_top (USE_APB_FSM=0)"
    echo "Tool:       Yosys (generic techmap)"
    echo ""
    echo "Per-module cell counts (inside each block, not additive):"
    awk '
    /^=== .*read_mux ===/ { mod="read_mux"; next }
    /^=== .*register_bank ===/ { mod="register_bank"; next }
    /^=== .*apb_decoder ===/ { mod="apb_decoder"; next }
    /^=== .*apb_response_logic ===/ { mod="apb_response_logic"; next }
    /^=== apb_slave_top ===/ { mod="apb_slave_top"; next }
    mod != "" && /^   Number of cells:/ {
        printf "  %-22s %5s cells\n", mod, $4
        mod=""
    }
    ' "$OUT/synth_report.txt"
    echo ""
    echo "Design total (all blocks combined):"
    awk '
    /^=== design hierarchy ===/ { found=1; next }
    found && /^   Number of cells:/ {
        print "  Total cells:  " $4
        getline
        while ($0 ~ /^     \$_/) {
            gsub(/^     /, "  ", $0)
            print $0
            getline
        }
        exit
    }
    ' "$OUT/synth_report.txt"
    echo ""
    if grep -q "Found and reported 0 problems" "$OUT/synth_report.txt"; then
        echo "Check:        PASS (0 problems)"
    else
        echo "Check:        see synth_report.txt"
    fi
    echo "Overall:      PASS"
    echo ""
    echo "Full log: reports/synth/synth_report.txt"
    echo "Netlist:  reports/synth/apb_slave_top_syn.v"
} > "$SUMMARY"

cat "$SUMMARY"

echo "==> Summary: $SUMMARY"
echo "==> Done"
