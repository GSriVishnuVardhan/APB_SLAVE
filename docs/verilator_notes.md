For Verilator 5.046, use:

apb_if #(ADDRESS_WIDTH, DATA_WIDTH) vif   // plain port, no virtual, no .driver
Keep modports in apb_if.sv for Questa later; they don’t go on submodule ports in Verilator

Verilator notes:

Module + task run() + mailbox port (same pattern as monitor)
No virtual interface on the scoreboard
inside {[8'h10:8'h4C]} — if Verilator complains, use explicit list or a case on a
