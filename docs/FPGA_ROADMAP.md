# FPGA Demo Roadmap (Level 5 — optional)

Not required for RTL freelancing, but high credibility for clients evaluating “can this engineer deliver on real hardware?”

## Target

- Xilinx Artix-7 or Intel Cyclone V dev board
- APB slave connected to a soft MicroBlaze / Nios II or static test master
- UART status print or LED blink on register write

## Steps

1. **Synthesis**
   - Add `rtl/` files to Vivado / Quartus project (no TB)
   - Clock constraint: 100 MHz (matches TB default)
   - Verify utilization < 1% LUT on typical dev kit

2. **On-chip test master**
   - Simple FSM master in RTL, or ARM bare-metal C driver via existing APB interconnect
   - Write `CTRL[0]` → toggle LED

3. **Bitstream**
   - Program `.bit` / `.sof`
   - Document programming steps in this file

4. **Demo video**
   - 30–60 s screen capture: register write → LED / UART response
   - Link from README

## Folder layout (future)

```
fpga/
  vivado/
    create_project.tcl
    constraints.xdc
  quartus/
    ...
  sw/          bare-metal test app (optional)
```

## Status

| Item | Status |
|------|--------|
| RTL synthesis clean | Pending |
| Vivado project | Not started |
| Bitstream | Not started |
| Demo video | Not started |

Contact via GitHub issues if you want FPGA bring-up as a paid milestone.
