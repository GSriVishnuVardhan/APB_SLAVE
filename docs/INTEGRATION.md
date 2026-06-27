# Integration Guide — APB3 Slave IP

## Top module

`apb_slave_top` — single-clock APB3 slave with internal address decode and register bank.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `USE_APB_FSM` | `0` | `1` = registered IDLE/SETUP/ACCESS FSM; `0` = combinational access phase |
| `MAX_WAIT_CYCLES` | `7` | Upper bound for `num_wait_cycles` port (counter width) |
| `ADDRESS_WIDTH` | `32` | APB address width |
| `DATA_WIDTH` | `32` | APB data width |
| `SLAVE_BASE_ADDR` | `32'h4000_0000` | SoC base address; must be 256-byte aligned (`[7:0]==0`) |
| `NUM_CTRL_REGS` | `4` | Control register count (fixed map) |
| `NUM_USER_REGS` | `16` | User register count |

Decode uses `paddr[7:0]` as offset from `SLAVE_BASE_ADDR` when the base is 256-byte aligned.

## Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | APB clock |
| `rst_n` | in | 1 | Active-low async reset |
| `psel` | in | 1 | Peripheral select |
| `penable` | in | 1 | Enable (ACCESS phase when high with `psel`) |
| `pwrite` | in | 1 | Write (`1`) / read (`0`) |
| `paddr` | in | `ADDRESS_WIDTH` | Full system address |
| `pwdata` | in | `DATA_WIDTH` | Write data |
| `num_wait_cycles` | in | `$clog2(MAX_WAIT_CYCLES+1)` | Wait states before completing transfer (0..MAX) |
| `pready` | out | 1 | Transfer complete (asserted one cycle per beat) |
| `pslverr` | out | 1 | Slave error |
| `prdata` | out | `DATA_WIDTH` | Read data |

## Instantiation example

```systemverilog
apb_slave_top #(
    .USE_APB_FSM       (1'b0),
    .MAX_WAIT_CYCLES   (7),
    .SLAVE_BASE_ADDR   (32'h4000_0000)
) u_apb_slave (
    .clk               (pclk),
    .rst_n             (presetn),
    .psel              (psel),
    .penable           (penable),
    .pwrite            (pwrite),
    .paddr             (paddr),
    .pwdata            (pwdata),
    .num_wait_cycles   (wait_cfg),   // tie to CSR or constant
    .pready            (pready),
    .pslverr           (pslverr),
    .prdata            (prdata)
);
```

## RTL file list (synthesis order)

```
rtl/apb_decoder.sv
rtl/register_bank.sv
rtl/apb_resp.sv
rtl/apb_slave_top.sv
```

## Memory map

See [`register_map.txt`](register_map.txt). Valid register window:

`SLAVE_BASE_ADDR + 0x00` … `SLAVE_BASE_ADDR + 0x4C`

Hole `0x50`..`0xFF` within the 256 B slot returns `PSLVERR`.

## Wait states

Drive `num_wait_cycles` before each transfer (or tie constant). The slave holds `pready` low for that many ACCESS cycles, then completes the beat in one cycle with `pready` high.

## Optional FSM mode

Set `USE_APB_FSM = 1` to enable registered protocol tracking and live STATUS register bits (busy, sticky error). Default verification regression uses `USE_APB_FSM = 0`; enable Test 10 in the testbench when validating FSM mode.

## Simulation (regression)

```bash
cd sim
./run_sim.sh
```

Check `reports/regression_report.txt` for pass/fail and `reports/coverage_summary.txt` for functional coverage bins.
