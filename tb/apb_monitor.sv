// APB Monitor
/*
apb_monitor.sv — for Verilator use a module with tasks (or package); Questa later can be a class:

Capture one beat per transfer on the PREADY=1 ACCESS cycle (APB3 completion cycle).
*/

`ifndef APB_MONITOR
`define APB_MONITOR
module apb_monitor
#(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    apb_if vif,
    mailbox mon_mbx,
    mailbox cov_mbx
);
    bit verbose = 1;

    task automatic monitor_apb();
        apb_transaction trans;

        forever begin
            wait (vif.penable && vif.psel && vif.pready);

            trans = new();
            trans.addr     = vif.paddr;
            trans.wdata    = vif.pwdata;
            trans.is_write = vif.pwrite;
            trans.is_read  = !vif.pwrite;
            trans.rdata    = vif.prdata;
            trans.slverr   = vif.pslverr;
            trans.ready    = vif.pready;
            mon_mbx.put(trans);
            cov_mbx.put(trans);
            if (verbose) $display("Monitor: Transaction: %s", trans.display());

            @(posedge vif.pclk);
            #1;
        end
    endtask
endmodule
`endif // APB_MONITOR
