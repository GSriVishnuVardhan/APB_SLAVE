// APB Interface
/*
Create apb_if.sv with clock, reset, APB signals, and modports (drv, mon).

Wire in TB — explicit port map (not .*):

apb_if vif(...);
apb_slave_top dut ( .clk(vif.PCLK), .psel(vif.PSEL), ... );
Drive vif.PSEL / vif.PADDR instead of psel / paddr in the test initial.

Rule: One driver only — don’t also assign vif.PSEL = psel*/

`ifndef APB_IF
`define APB_IF
interface apb_if
#(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32
);
    logic pclk, rst_n;
    logic psel, penable, pwrite;
    logic [ADDRESS_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic pslverr, pready;

    modport driver(
        input pclk, pready, pslverr, prdata,
        output psel, rst_n, penable, pwrite, paddr, pwdata
    );
    modport monitor(
        input pclk, rst_n, psel, penable, pwrite, paddr, pwdata, prdata, pslverr, pready
    );
    modport dut(
        input pclk, rst_n, psel, penable, pwrite, paddr, pwdata,
        output prdata, pslverr, pready
    );
    
endinterface
`endif // APB_IF
