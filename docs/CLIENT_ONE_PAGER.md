# APB3 Slave IP — Client Summary

**Engineer:** [GSriVishnuVardhan](https://github.com/GSriVishnuVardhan)  
**Deliverable:** Production-style APB3 register slave + UVM-lite verification environment  
**Repo:** [APB_SLAVE](https://github.com/GSriVishnuVardhan/APB_SLAVE)

---

## Problem

You need a **reusable, verified APB3 peripheral slave** that integrates into an SoC or FPGA design — with clear register map, error handling, wait-state support, and regression evidence.

## Solution

A **parameterized, modular APB3 slave** with:

- Hierarchical RTL (`decoder`, `register_bank`, `read_mux`, `response_logic`)
- 20 memory-mapped registers (4 control + 16 user)
- Configurable wait states and optional protocol FSM
- Illegal-address and read-only violation → `PSLVERR`

## Verification (included)

| Item | Status |
|------|--------|
| UVM-lite TB (driver, monitor, scoreboard, ref model) | ✅ |
| 10 directed tests (reset, sweep, stress, random, SLVERR, wait) | ✅ 10/10 PASS |
| Functional coverage | ✅ 100% (24/24 bins) |
| Protocol checker + SVA assertions | ✅ 0 violations |
| RTL lint (Verilator) | ✅ PASS |

## Typical deliverables for a client engagement

| Phase | Output | Est. effort |
|-------|--------|-------------|
| **1. Spec review** | Register map, timing, error rules | 0.5–1 day |
| **2. RTL** | Lint-clean, parameterized SV | 2–4 days |
| **3. Verification** | TB, tests, coverage, regression report | 3–5 days |
| **4. Integration** | Instantiation guide, file list, review | 0.5–1 day |
| **5. FPGA (optional)** | Vivado project, bitstream, demo | 3–5 days |

*Timeline varies with register count, custom logic, and simulator requirements.*

## What you receive

- Synthesizable SystemVerilog RTL (`rtl/`)
- Complete testbench with scoreboard + reference model (`tb/`)
- Regression and coverage reports (`reports/`)
- Design spec, register map, integration guide (`docs/`)
- One round of integration support (scope TBD)

## Out of scope (unless quoted separately)

- Full UVM / VIP migration
- Formal verification
- FPGA board bring-up (see [FPGA_ROADMAP.md](FPGA_ROADMAP.md))
- AHB/AXI bridge or interconnect design

## How to evaluate this IP (5 minutes)

1. Read [README.md](../README.md) — overview, register map, block diagram  
2. Open [VERIFICATION_RESULTS.md](VERIFICATION_RESULTS.md) — regression + coverage  
3. Skim `rtl/apb_slave_top.sv` — top-level ports and parameters  
4. Run `cd sim && make lint && make sim` — confirm PASS locally  

## Contact

GitHub: [@GSriVishnuVardhan](https://github.com/GSriVishnuVardhan)  
Open an issue on the repo for licensing or custom IP inquiries.
