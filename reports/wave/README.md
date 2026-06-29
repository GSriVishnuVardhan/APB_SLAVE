# Waveform capture (GTKWave / FST)

## Generate FST

```bash
cd sim
make wave
```

## Open in GTKWave (MSYS2 MINGW64)

**Install GTKWave first** (one-time):

```bash
pacman -S mingw-w64-x86_64-gtkwave
```

Close and reopen your MINGW64 terminal, then:

```bash
cd sim
make wave-view
```

This opens `reports/wave/apb_wave.fst` with a Tcl script that pre-loads APB signals.

**Manual open** (if `make wave-view` fails):

```bash
cd reports/wave
gtkwave apb_wave.fst apb_wave.tcl
```

Do **not** use the old `apb_wave.gtkw` save file — it had wrong signal paths and can cause GTKWave errors on MSYS.

## Signal names (Verilator hierarchy)

| Signal | Path |
|--------|------|
| Clock | `tb_apb_wave.vif.pclk` |
| Reset | `tb_apb_wave.vif.rst_n` |
| PSEL | `tb_apb_wave.vif.psel` |
| PENABLE | `tb_apb_wave.vif.penable` |
| PWRITE | `tb_apb_wave.vif.pwrite` |
| PADDR | `tb_apb_wave.vif.paddr` |
| PWDATA | `tb_apb_wave.vif.pwdata` |
| PRDATA | `tb_apb_wave.vif.prdata` |
| PREADY | `tb_apb_wave.vif.pready` |
| PSLVERR | `tb_apb_wave.vif.pslverr` |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `gtkwave: command not found` | `pacman -S mingw-w64-x86_64-gtkwave`, new shell |
| FST missing | Run `cd sim && make wave` first |
| Empty wave viewer | Use `apb_wave.tcl` or add signals from SST tree |

Portfolio PNGs: [`docs/images/gtkwave/`](../docs/images/gtkwave/)
