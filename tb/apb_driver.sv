// APB Driver
/*
apb_driver.sv — for Verilator use a module with tasks (or package); Questa later can be a class:

reset_dut()
apb_write(addr, data, slverr)
apb_read(addr, data, slverr)

APB3 beat sequence (matches week5 spec / TB comment):
  SETUP:  PSEL=1, PENABLE=0
  ACCESS: PSEL=1, PENABLE=1, wait until PREADY=1 (last ACCESS cycle)
  Sample prdata/pslverr during the PREADY=1 cycle
  Next posedge: deassert PSEL and PENABLE
*/

`ifndef APB_DRIVER
`define APB_DRIVER
module apb_driver
#(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    apb_if vif
);
    bit verbose = 1;
    bit quiet_errors = 0;

    task reset_dut();
        vif.rst_n = 1;
        @(posedge vif.pclk);
        vif.rst_n = 0;
        $display("Reset asserted for 3 cycles");
        repeat(3) @(posedge vif.pclk);
        vif.rst_n = 1;
        $display("Reset deasserted");
    endtask

    task apb_write(input logic [ADDRESS_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data, output bit slverr);
        slverr = 0;
        if (verbose) $display("Writing to register %h", addr);
        vif.paddr   = addr;
        vif.pwdata  = data;
        vif.pwrite  = 1;
        vif.psel    = 1;
        vif.penable = 0;
        @(posedge vif.pclk);

        vif.penable = 1;
        wait(vif.penable && vif.psel && vif.pready);

        slverr = vif.pslverr;
        if (vif.pslverr == 1) begin
            if (!quiet_errors) $display("Write failed: pslverr asserted: %h", vif.pslverr);
        end
        else if (verbose) $display("Write complete: Data written to register %h is %h and pslverr is %b", addr, data, slverr);

        @(posedge vif.pclk);
        #1;
        vif.psel    = 0;
        vif.penable = 0;
        vif.pwrite  = 0;
        if (verbose) $display("Write complete");
    endtask

    task apb_read(input logic [ADDRESS_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data, output bit slverr);
        slverr = 0;
        data   = 0;
        if (verbose) $display("Reading from register %h", addr);
        vif.paddr   = addr;
        vif.pwrite  = 0;
        vif.psel    = 1;
        vif.penable = 0;
        @(posedge vif.pclk);

        vif.penable = 1;
        wait(vif.penable && vif.psel && vif.pready);

        data   = vif.prdata;
        slverr = vif.pslverr;
        if (vif.pslverr == 1) begin
            if (!quiet_errors) $display("Read failed: pslverr asserted: %h", vif.pslverr);
        end
        else if (verbose) $display("Read complete: Data read from register %h is %h and pslverr is %b", addr, data, slverr);

        @(posedge vif.pclk);
        #1;
        vif.psel    = 0;
        vif.penable = 0;
    endtask
endmodule
`endif // APB_DRIVER
