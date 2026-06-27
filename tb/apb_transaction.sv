// APB Transaction
/*
apb_transaction.sv — record of one completed beat:

addr, wdata, rdata, is_write, is_read, slverr, ready
*/

`ifndef APB_TRANSACTION
`define APB_TRANSACTION
class apb_transaction
#(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32
);
    // Fields
    logic clk, rst_n;
    logic [ADDRESS_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    logic is_write, is_read, slverr, ready;

    // Constraints
    constraint c_addr {
        addr inside {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19};
    }

// Initialization Constructor
function new();
    this.clk = 0; // Clock
    this.rst_n = 1; // Reset high initially
    this.addr = 0; // Address of the register
    this.wdata = 0; // Data to write to the register
    this.is_write = 0; // Is write transaction
    this.is_read = 0; // Is read transaction
    this.slverr = 0; // No slave error
    this.ready = 0; // No ready
    this.rdata = 0; // No data read
endfunction


// Display
function string display();
    return $sformatf("Address: %h, Write data: %h, Read data: %h, Is write: %b, Is read: %b, Slave error: %b, Ready: %b", addr, wdata, rdata, is_write, is_read, slverr, ready);
endfunction
endclass
`endif // APB_TRANSACTION
