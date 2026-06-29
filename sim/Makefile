# Simulation Makefile — run from sim/ (MSYS2 make, or: bash run_sim.sh)

ROOT     := ..
SIM_DIR  := .
TOP      := tb_apb_slave
OUT      := obj_dir/V$(TOP)
REPORTS  := $(ROOT)/reports

RTL := $(ROOT)/rtl/read_mux.sv \
       $(ROOT)/rtl/apb_decoder.sv \
       $(ROOT)/rtl/register_bank.sv \
       $(ROOT)/rtl/apb_response_logic.sv \
       $(ROOT)/rtl/apb_slave_top.sv

TB  := $(ROOT)/tb/apb_if.sv \
       $(ROOT)/tb/apb_transaction.sv \
       $(ROOT)/tb/apb_ref_model.sv \
       $(ROOT)/tb/apb_driver.sv \
       $(ROOT)/tb/apb_monitor.sv \
       $(ROOT)/tb/apb_scoreboard.sv \
       $(ROOT)/tb/apb_coverage.sv \
       $(ROOT)/tb/apb_protocol_checker.sv \
       $(ROOT)/tb/tb_apb_slave.sv

VERILATOR := verilator --timing --binary -Wall -Wno-fatal --sv

.PHONY: all sim lint clean wave help ci-local

all: sim

help:
	@echo "Targets:"
	@echo "  make sim        — compile + run regression (Verilator)"
	@echo "  make lint       — RTL lint-only (Verilator)"
	@echo "  make ci-local   — mirror GitHub CI (lint + sim + wave + synth)"
	@echo "  make wave-view — open FST in GTKWave"
	@echo "  make synth  — Yosys open-source synthesis"
	@echo "  make clean  — remove obj_dir"

sim:
	@bash run_sim.sh

lint:
	@bash lint.sh

ci-local:
	@bash run_ci_local.sh

wave:
	@bash run_wave.sh

wave-view:
	@bash open_wave.sh

synth:
	@bash synth.sh

docker-checks:
	@bash run_docker_checks.sh

clean:
	rm -rf obj_dir

# --- Optional simulator stubs (fill in tool paths on your machine) ---
# questa:
# 	vlog -sv +incdir+$(ROOT)/tb $(RTL) $(TB) $(ROOT)/tb/apb_assertions.sv
# 	vsim -c $(TOP) -do "run -all; quit -code [expr [coverage attribute -name TESTSTATUS] == 0]"
#
# xrun:
# 	xrun -sv -top $(TOP) -f filelist.f $(ROOT)/tb/apb_assertions.sv
