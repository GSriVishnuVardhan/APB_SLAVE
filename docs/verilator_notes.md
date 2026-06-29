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

Use a **typed** mailbox in module port lists:

```systemverilog
mailbox #(apb_transaction) mon_mbx   // OK
```

Do **not** use an untyped mailbox — Verilator reports `Class parameter type without default value: 'T'`:

```systemverilog
mailbox mon_mbx   // ERROR on 5.046+
```

Do **not** replace mailboxes with `input logic` / `input apb_transaction` handshakes; coverage and scoreboard need blocking `get()`.

Pattern: module + `task run()` + typed mailbox port (monitor, scoreboard, coverage).

## Other

- No virtual interface on driver/monitor/scoreboard.
- `inside {[8'h10:8'h4C]}` — if Verilator complains, use explicit list or `case`.
