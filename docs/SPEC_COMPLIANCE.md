# Spec compliance audit (RTL + TB vs docs)

Audit date: project handoff for GitHub repo **APB_SLAVE**.

## Summary

| Area | Verdict |
|------|---------|
| Register map & addressing | **PASS** (compact window 0x00..0x4C) |
| RW / RO / SLVERR rules | **PASS** |
| APB3 wait states & pready | **PASS** |
| Reset behavior | **PASS** |
| Optional FSM | **PASS** (parameterized; TB default USE_APB_FSM=0) |
| Verification tests 1–9 | **PASS** |
| Test 10 (FSM STATUS) | **PASS** when USE_APB_FSM=1 |
| Functional coverage | **PASS** (100% / 24 bins) |
| Spec documents updated | **PASS** (this audit) |

## RTL vs design_spec.txt

| Requirement | Implementation | Match |
|-------------|----------------|-------|
| 32-bit addr/data | `ADDRESS_WIDTH`, `DATA_WIDTH` | Yes |
| 20 registers @ BASE+0..0x4C | decoder `in_window` | Yes |
| Hole 0x50..0xFF → SLVERR | outside compact window → `!offset_valid` | Yes |
| Unaligned → SLVERR | `paddr[1:0]==0` check | Yes |
| STATUS write → SLVERR | `write && status_reg` in resp | Yes |
| Writable regs reset to 0 | register_bank async reset | Yes |
| num_wait_cycles 0..7 | runtime port + `MAX_WAIT_CYCLES` | Yes (spec updated) |
| PREADY single completion cycle | `wait_done` comb in resp | Yes (spec updated) |
| USE_APB_FSM optional | top/decoder/resp/reg bank param | Yes |
| STATUS live busy/error | only when USE_APB_FSM=1 | Yes |
| CTRL bits side-effects | storage only | Spec notes storage-only |
| read_mux block | inside register_bank comb | Yes (spec updated) |

## TB vs verification_spec.txt

| Requirement | Implementation | Match |
|-------------|----------------|-------|
| Tests 1–7 | tb_apb_slave tasks | Yes |
| Tests 8–9 wait sweep | implemented | Yes |
| Test 10 FSM | conditional on USE_APB_FSM | Yes |
| Scoreboard ref model | apb_scoreboard.sv | Yes |
| Coverage bins | apb_coverage.sv 24 bins | Yes |
| Coverage >95% | 100% on regression | Yes |
| Protocol checks (Verilator) | apb_protocol_checker.sv | Yes (spec updated) |
| SVA assertions | Questa only; disabled Verilator | Yes (spec updated) |
| regression_report.txt | generated end of sim | Yes |

## Minor gaps (acceptable / documented)

1. **Test 6** does not use offset exactly `0x50`; uses `0x6c` (still illegal hole). Random test may hit 0x50..0xFF.
2. **Assertions** “write once / read correct” — enforced by scoreboard, not SVA under Verilator.
3. **CTRL Enable/IE** — no functional logic (spec says storage only).
4. **TB default** `USE_APB_FSM=0`; Test 10 skipped unless enabled.
5. **archive/** — development history; not in sim filelist.

## GitHub upload checklist

- [x] Specs aligned with RTL/TB
- [x] Root README.md + .gitignore
- [x] No stray build artifacts committed (obj_dir gitignored)
- [ ] Rename local folder to `APB_SLAVE` or clone repo into that name
- [ ] `git init`, commit, push to github.com/.../APB_SLAVE
