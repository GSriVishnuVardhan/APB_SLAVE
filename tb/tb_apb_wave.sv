// Minimal APB wave capture TB — short stimulus for GTKWave / FST review.
// Separate from full regression TB to avoid Verilator trace + fork internal error.

`timescale 1ns/1ps

module tb_apb_wave;
    localparam ADDRESS_WIDTH   = 32;
    localparam SLAVE_BASE_ADDR = 32'h4000_0000;
    localparam DATA_WIDTH      = 32;
    localparam MAX_WAIT_CYCLES = 7;
    localparam PERIOD          = 10;
    localparam HALF_PERIOD     = PERIOD / 2;

    logic [$clog2(MAX_WAIT_CYCLES+1)-1:0] num_wait_cycles_cfg = 3'd2;
    logic [DATA_WIDTH-1:0] rdata;
    bit slverr;

    apb_slave_top #(
        .USE_APB_FSM     (1'b1),
        .MAX_WAIT_CYCLES (MAX_WAIT_CYCLES),
        .ADDRESS_WIDTH   (ADDRESS_WIDTH),
        .SLAVE_BASE_ADDR (SLAVE_BASE_ADDR),
        .DATA_WIDTH      (DATA_WIDTH),
        .NUM_CTRL_REGS   (4),
        .NUM_USER_REGS   (16)
    ) dut (
        .clk             (vif.pclk),
        .rst_n           (vif.rst_n),
        .num_wait_cycles (num_wait_cycles_cfg),
        .psel            (vif.psel),
        .penable         (vif.penable),
        .pwrite          (vif.pwrite),
        .paddr           (vif.paddr),
        .pwdata          (vif.pwdata),
        .pslverr         (vif.pslverr),
        .pready          (vif.pready),
        .prdata          (vif.prdata)
    );

    apb_if #(
        .ADDRESS_WIDTH (ADDRESS_WIDTH),
        .DATA_WIDTH    (DATA_WIDTH)
    ) vif();

    apb_driver #(
        .ADDRESS_WIDTH (ADDRESS_WIDTH),
        .DATA_WIDTH    (DATA_WIDTH)
    ) drv (.vif(vif));

    initial begin
        vif.pclk = 0;
        forever #HALF_PERIOD vif.pclk = ~vif.pclk;
    end

    initial begin
        vif.psel    = 0;
        vif.penable = 0;
        vif.pwrite  = 0;
        vif.paddr   = 0;
        vif.pwdata  = 0;

        drv.verbose = 0;
        drv.reset_dut();

        drv.apb_write(SLAVE_BASE_ADDR + 0, 32'hDEAD_BEEF, slverr);
        drv.apb_read(SLAVE_BASE_ADDR + 0, rdata, slverr);

        drv.quiet_errors = 1;
        drv.apb_write(SLAVE_BASE_ADDR + 32'h80, 32'h0, slverr);

        #50;
        $display("Wave capture complete — open reports/wave/apb_wave.fst in GTKWave");
        $finish;
    end

    initial begin
        #500_000;
        $fatal("Wave TB timeout");
    end
endmodule
