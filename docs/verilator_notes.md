# Verilator constraints (APB_SLAVE TB)

Tested: Verilator 5.046 (MSYS2). CI: Ubuntu apt Verilator 5.020+.

## Interface ports

Use an **unparameterized** interface in submodule port lists:

```systemverilog
apb_if vif   // OK — defaults ADDRESS_WIDTH=32, DATA_WIDTH=32
```

Do **not** pass `#(ADDRESS_WIDTH, DATA_WIDTH)` on the port (older Verilator rejects parameterized interface ports):

```systemverilog
apb_if #(ADDRESS_WIDTH, DATA_WIDTH) vif   // avoid on submodule ports
```

Keep modports in `apb_if.sv` for Questa later; they are not used on Verilator submodule ports.

## Mailboxes

Verilator **5.020** rejects parameterized mailboxes in **module port lists** (`UNSUPPORTED: Ranges ignored in port-lists`). Verilator **5.046** rejects **untyped** `mailbox` ports (`Class parameter type 'T' without default`).

Use **internal** typed mailboxes plus a **setter** from the testbench (before `fork`):

```systemverilog
// Inside monitor / scoreboard / coverage (not in port list)
mailbox #(apb_transaction) mon_mbx;

function void set_mailbox(mailbox #(apb_transaction) mb);
    mon_mbx = mb;
endfunction
```

```systemverilog
// tb_apb_slave initial block
mon.set_mailboxes(mon_mbx, cov_mbx);
sb.set_mailbox(mon_mbx);
cov.set_mailbox(cov_mbx);
```

Do **not** use untyped `mailbox` or `input apb_transaction` signal handshakes.

## Other

- No virtual interface on driver/monitor/scoreboard.
- `inside {[8'h10:8'h4C]}` — if Verilator complains, use explicit list or `case`.
