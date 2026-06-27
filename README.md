# APB3 Slave Peripheral IP

Reusable **AMBA APB3 slave** with a 20-register bank, configurable wait states, optional protocol FSM, and a self-checking SystemVerilog testbench verified with Verilator.

Designed as a portfolio-quality RTL block for SoC integration.

## Verification status

| Metric | Result |
|--------|--------|
| Directed tests | 10 / 10 pass |
| Scoreboard errors | 0 |
| Protocol violations | 0 |
| Functional coverage | **100%** (24 / 24 bins, goal ≥ 95%) |

Artifacts: [`reports/regression_report.txt`](reports/regression_report.txt), [`reports/coverage_summary.txt`](reports/coverage_summary.txt)

Spec audit: [`docs/SPEC_COMPLIANCE.md`](docs/SPEC_COMPLIANCE.md)

## Features

- 32-bit address and data; default base `0x4000_0000` (256-byte aligned window)
- 4 control + 16 user registers — see [`docs/register_map.txt`](docs/register_map.txt)
- Runtime **`num_wait_cycles`** (0–7): APB3 wait states before `pready` asserts
- Optional **`USE_APB_FSM`**: IDLE / SETUP / ACCESS FSM with live STATUS busy/error bits
- Illegal address, unaligned access, and STATUS write → `PSLVERR`
- Modular RTL: decoder, register bank, response logic, top wrapper

## Quick start

**Requirements:** Verilator 5.x, MSYS2 MINGW64 (or Linux with Verilator in `PATH`)

```bash
cd sim
./run_sim.sh
```

Reports are written to `reports/` (`sim.log`, `regression_report.txt`, `coverage_summary.txt`).

## Repository layout

| Path | Description |
|------|-------------|
| `rtl/` | Synthesizable DUT — `apb_slave_top`, decoder, register bank, response logic |
| `tb/` | UVM-style SV env: driver, monitor, scoreboard, coverage, protocol checker |
| `sim/` | Verilator compile/run script and file list |
| `docs/` | Design spec, verification plan, register map, integration guide, PDFs |
| `reports/` | Checked-in regression and coverage summaries (re-run sim to refresh) |

## Documentation

| Document | Purpose |
|----------|---------|
| [Design spec](docs/design_spec.txt) | RTL parameters, protocol behavior, FSM option |
| [Verification spec](docs/verification_spec.txt) | Test list, scoreboard rules, coverage goals |
| [Register map](docs/register_map.txt) | Offsets, RW/RO, addressing rules |
| [Integration guide](docs/INTEGRATION.md) | Instantiation, ports, synthesis file list |
| [Verilator notes](docs/verilator_notes.md) | Simulator constraints and workarounds |
| [Project README](docs/README.md) | Milestones and directory overview |

## Milestones

| Milestone | Description | Status |
|-----------|-------------|--------|
| M0 | Design + verification specifications | Done |
| M1 | Minimal RTL + testbench MVP | Done |
| M2 | Full directed + random test suite | Done |
| M3 | Functional coverage, protocol checker, regression reports | Done |

## Integration

Instantiate `apb_slave_top` on your APB fabric. See [`docs/INTEGRATION.md`](docs/INTEGRATION.md) for parameters, port list, and RTL file order.

```systemverilog
apb_slave_top #(
    .USE_APB_FSM       (1'b0),
    .SLAVE_BASE_ADDR   (32'h4000_0000),
    .MAX_WAIT_CYCLES   (7)
) u_apb_slave (
    .clk               (pclk),
    .rst_n             (presetn),
    .psel              (psel),
    .penable           (penable),
    .pwrite            (pwrite),
    .paddr             (paddr),
    .pwdata            (pwdata),
    .num_wait_cycles   (3'd2),
    .pready            (pready),
    .pslverr           (pslverr),
    .prdata            (prdata)
);
```

## Tooling

- **Simulation:** Verilator 5.x (`--timing --binary --sv`)
- **Synthesis:** Standard SystemVerilog-2012 subset; no vendor primitives in RTL

## License

Apache License 2.0 — see [LICENSE](LICENSE).

This repository is a public portfolio reference. For commercial redistribution, white-label delivery, or project-specific licensing, contact the maintainer via GitHub.

## Author

[GSriVishnuVardhan](https://github.com/GSriVishnuVardhan)
