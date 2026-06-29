# APB3 Slave Peripheral — Project Docs

## Milestones

| Milestone | Status | Description |
|-----------|--------|-------------|
| M0 | Done | Design + verification specs (`design_spec.txt`, `verification_spec.txt`) |
| M1 | Done | Minimal RTL + testbench MVP |
| M2 | Done | Full RTL, driver/monitor/scoreboard, tests 1–10 |
| M3 | Done | Functional coverage, protocol checker, regression + coverage reports |

## Layout

```
docs/     Specifications and register map
rtl/      DUT (apb_slave_top, decoder, register_bank, read_mux, apb_response_logic)
tb/       Testbench, scoreboard, coverage, protocol checker
sim/      run_sim.sh, filelist.f, build artifacts (obj_dir/)
reports/  Generated: sim.log, coverage_summary.txt, regression_report.txt
```

## Run simulation

From MSYS2 MINGW64:

```bash
cd sim
./run_sim.sh
```

Reports are written to `reports/`:
- `regression_report.txt` — pass/fail, scoreboard errors, protocol violations, coverage goal
- `coverage_summary.txt` — per-bin functional coverage
- `sim.log` — full simulation console log

## M3 exit criteria (from verification spec)

- No scoreboard mismatches
- No protocol violations
- Functional coverage ≥ 95%

## Key docs

- `design_spec.txt` — RTL parameters, memory map, protocol, optional FSM
- `verification_spec.txt` — tests, scoreboard, coverage goals
- `register_map.txt` — register offsets and fields
- `verilator_notes.md` — Verilator 5.x constraints
- `CLIENT_ONE_PAGER.md` — freelance / client proposal summary
- `images/apb_block_diagram.svg` — RTL block diagram (PNG export available)
