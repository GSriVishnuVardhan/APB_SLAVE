# Verification Environment Architecture

UVM-lite structure suitable for Verilator today and migration to UVM/Questa later.

## Block diagram

```
                    ┌─────────────────────────────────────────┐
                    │            tb_apb_slave                 │
                    │  ┌─────────┐         ┌───────────────┐  │
                    │  │  tests  │────────▶│  apb_driver   │──┼──▶ apb_if ──▶ DUT
                    │  └─────────┘         └───────────────┘  │
                    │                           │              │
                    │                    ┌──────▼──────┐       │
                    │                    │ apb_monitor │       │
                    │                    └──────┬──────┘       │
                    │              mailbox      │              │
                    │         ┌─────────────────┼──────────┐   │
                    │         ▼                 ▼          ▼   │
                    │  apb_scoreboard    apb_coverage  (log)   │
                    │         │ uses                             │
                    │         ▼                                  │
                    │  apb_ref_model  ◀── golden register model  │
                    │                                            │
                    │  apb_protocol_checker  (Verilator SVA)     │
                    │  apb_assertions.sv     (Questa/Xcelium)    │
                    └─────────────────────────────────────────┘
```

## Components

| File | Role |
|------|------|
| `apb_if.sv` | Virtual interface — clock, reset, APB signals |
| `apb_transaction.sv` | Transaction class (addr, data, r/w, slverr, ready) |
| `apb_driver.sv` | Stimulus — SETUP → ACCESS → wait `pready` |
| `apb_monitor.sv` | Observes completed beats; fans out mailboxes |
| `apb_ref_model.sv` | **Reference model** — register array + decode/SLVERR rules |
| `apb_scoreboard.sv` | Compares monitor transactions vs ref model |
| `apb_coverage.sv` | Functional covergroups (24 bins) |
| `apb_protocol_checker.sv` | Procedural protocol checks (Verilator) |
| `apb_assertions.sv` | SVA properties (event simulators) |
| `tb_apb_slave.sv` | Top test — 10 directed tests + report generation |

## Test list

| # | Name | Purpose |
|---|------|---------|
| 1 | Reset | All registers read back 0 |
| 2 | Single write/read | Basic data path |
| 3 | Full register sweep | Every legal register |
| 4 | 100 back-to-back writes | Throughput |
| 5 | 100 back-to-back reads | Read stability |
| 6 | Illegal access | SLVERR on bad addr / STATUS write |
| 7 | Random R/W | 2222+ random transactions |
| 8 | Wait cycle sweep | `num_wait_cycles` 0..7 |
| 9 | Random wait | 10 random wait settings |
| 10 | FSM STATUS | Live busy/error (when `USE_APB_FSM=1`) |

## Exit criteria

- Scoreboard errors = 0
- Protocol violations = 0
- Functional coverage ≥ 95% (current: 100%)

Reports: `reports/regression_report.txt`, `reports/coverage_summary.txt`

## Running on other simulators

**Questa / ModelSim**

```tcl
vlog -sv -f filelist.f ../tb/apb_assertions.sv
vsim -c tb_apb_slave -do "run -all; quit"
```

**Xcelium**

```bash
xrun -sv -top tb_apb_slave -f filelist.f ../tb/apb_assertions.sv
```

**Icarus (limited SV — not recommended for this TB)**

This TB uses mailboxes, classes, and `--timing`; use Verilator 5.x or a commercial simulator.
