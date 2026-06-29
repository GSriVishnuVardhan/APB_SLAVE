# Synthesis Results (Yosys)

Open-source synthesis using [Yosys](https://yosyshq.net/yosys/) on RTL (`USE_APB_FSM=0` default).

## Generic vs technology mapping

**Important:** The flow in this repo is **RTL elaboration + generic logic synthesis**, not mapping to a foundry node or FPGA device. That is intentional for a portfolio IP block — it proves the RTL is synthesizable without requiring a paid PDK or Vivado license.

### What “real” synthesis uses

Production flows map RTL to **technology-specific cells** from a vendor library:

| Target | Tool (examples) | Library | Typical output cells |
|--------|-----------------|---------|----------------------|
| **ASIC** | Design Compiler, Genus, OpenROAD | Foundry `.lib` (TSMC, Sky130, …) | `NAND2_X1`, `DFFR_X1`, … |
| **FPGA** | Vivado, Quartus | Vendor primitives | `LUT6`, `FDRE`, `CARRY4`, … |

Those flows report **real** LUT/FF/slice utilization (FPGA) or gate area and timing (ASIC) for a specific part and corner.

### What this repo’s Yosys flow uses

Script: [`sim/synth.ys`](../sim/synth.ys)

```text
read_verilog -sv  →  hierarchy  →  proc; opt; fsm; memory; opt  →  techmap; opt  →  stat; check
```

There is **no** `read_liberty`, **no** `dfflibmap -liberty`, and **no** `abc -liberty`. The `techmap` pass maps logic to Yosys **internal generic cells**:

| Cell in report | Role | Technology-specific? |
|----------------|------|--------------------|
| `$_AND_`, `$_OR_`, `$_NOT_` | Generic combinational gates | No |
| `$_MUX_` | Generic multiplexer | No |
| `$_DFFE_PN0P_` | Generic DFF (clock-enabled, active-low async reset) | No |
| `$_XOR_` | Generic XOR | No |

So **2187 cells** means “2187 abstract gates/FFs after logic optimization” — **not** “2187 LUTs on Artix-7” or “2187 gates in 28 nm TSMC”.

### What this flow proves

| Goal | Status |
|------|--------|
| RTL elaborates without syntax/latch errors | ✅ |
| Registers and combinational logic infer cleanly | ✅ |
| Hierarchy preserved through `check` | ✅ |
| Structural netlist produced | ✅ [`apb_slave_top_syn.v`](../reports/synth/apb_slave_top_syn.v) |
| Area / Fmax for a specific silicon or FPGA part | ❌ Not in scope (needs technology library) |

### Getting technology-mapped results (future)

| Target | Next step | Doc |
|--------|-----------|-----|
| **Xilinx FPGA** | Vivado `synth_design -top apb_slave_top -part <device>` | [FPGA_ROADMAP.md](FPGA_ROADMAP.md) |
| **Open-source ASIC (e.g. Sky130)** | Add `read_liberty` + `dfflibmap` + `abc -liberty` to a new `synth_sky130.ys` | — |
| **Commercial ASIC** | Hand RTL + constraints to DC/Genus with foundry `.lib` | Client engagement |

For freelancing, describe this flow as **“Yosys generic synthesis — synthesizability sign-off”**; quote Vivado/DC mapping as a separate milestone when the client specifies a part or PDK.

## Run
```bash
cd sim
make synth
```

Readable summary: [`reports/synth/synth_summary.txt`](../reports/synth/synth_summary.txt)  
Full log: [`reports/synth/synth_report.txt`](../reports/synth/synth_report.txt)

## How to read the numbers

Yosys `stat` prints **one section per module**, then a **design total**. The per-module counts are **not meant to be added** — submodule logic is already included in the design total.

| Section | Meaning | Example |
|---------|---------|---------|
| `read_mux` | Cells inside the read mux | 1300 |
| `register_bank` | Register FFs + mux instance | 633 |
| `apb_decoder` | Address decode logic | 215 |
| `apb_response_logic` | PREADY / PSLVERR | 39 |
| `apb_slave_top` | Top-level wiring only | 4 |
| **design hierarchy** | **Flattened total for the whole IP** | **2187** |

Only the **design hierarchy** row is the chip-level resource count.

## Latest result

| Metric | Value |
|--------|-------|
| Design total cells | **2187** |
| Flip-flops (`$_DFFE_PN0P_`) | **611** |
| AND / OR / MUX | 764 / 652 / 108 |
| Check | **0 problems** |

Netlist: [`reports/synth/apb_slave_top_syn.v`](../reports/synth/apb_slave_top_syn.v)

## Flow

[`sim/synth.ys`](../sim/synth.ys): `read_verilog → hierarchy → proc → opt → fsm → memory → techmap → stat → check → write_verilog`
