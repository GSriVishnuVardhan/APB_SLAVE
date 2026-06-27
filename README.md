# APB_SLAVE

Parameterized **APB3 slave peripheral** with 20-register bank, configurable wait states, optional protocol FSM, and self-checking Verilator testbench.

## Features

- 32-bit address/data, base `0x4000_0000`
- 4 control + 16 user registers (see `docs/register_map.txt`)
- Runtime `num_wait_cycles` (0–7): APB3 wait states before `pready`
- Optional `USE_APB_FSM`: IDLE/SETUP/ACCESS FSM + live STATUS busy/error
- Illegal address and STATUS-write → `PSLVERR`

## Quick start

MSYS2 MINGW64:

```bash
cd sim
./run_sim.sh
```

Reports: `reports/regression_report.txt`, `reports/coverage_summary.txt`

## Repository layout

| Directory | Contents |
|-----------|----------|
| `docs/` | Design + verification specs, register map, PDFs |
| `rtl/` | `apb_slave_top`, decoder, register bank, response logic |
| `tb/` | Driver, monitor, scoreboard, coverage, protocol checker |
| `sim/` | Verilator build script |
| `reports/` | Generated regression artifacts |
| `archive/` | Historical phase snapshots (not used in build) |

## Milestones

| Milestone | Status |
|-----------|--------|
| M0 Spec | Done |
| M1 MVP | Done (`archive/`) |
| M2 Tested IP | Done — 10 directed tests |
| M3 Sellable IP | Done — coverage ≥95%, regression report |

## Documentation

- [Design spec](docs/design_spec.txt)
- [Verification spec](docs/verification_spec.txt)
- [Project README](docs/README.md)

## Tooling

- Verilator 5.x (`--timing --binary --sv`)
- See `docs/verilator_notes.md`
