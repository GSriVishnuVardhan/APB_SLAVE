// APB Slave Top

module apb_slave_top
#(
    parameter USE_APB_FSM = 0,
    parameter MAX_WAIT_CYCLES = 7,
    parameter ADDRESS_WIDTH = 32,
    parameter logic [ADDRESS_WIDTH-1:0] SLAVE_BASE_ADDR = 32'h4000_0000,
    parameter DATA_WIDTH = 32,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)
(
    input clk, rst_n, psel, penable, pwrite,
    input logic [$clog2(MAX_WAIT_CYCLES+1)-1:0] num_wait_cycles,
    input [ADDRESS_WIDTH-1:0] paddr,
    input [DATA_WIDTH-1:0] pwdata,
    output logic pslverr,
    output logic pready,
    output logic [DATA_WIDTH-1:0] prdata
);

    logic offset_valid;
    logic [NUM_REGS-1:0] reg_sel;
    logic apb_access;
    logic state_access;
    logic busy;
    logic error_sticky;

    assign apb_access = psel & penable;

    apb_response_logic
    #(
        .USE_APB_FSM(USE_APB_FSM),
        .MAX_WAIT_CYCLES(MAX_WAIT_CYCLES)
    )
    response_logic_inst
    (
        .num_wait_cycles(num_wait_cycles),
        .pclk(clk),
        .rst_n(rst_n),
        .psel(psel),
        .penable(penable),
        .apb_access(apb_access),
        .offset_valid(offset_valid),
        .write(pwrite),
        .pslverr(pslverr),
        .status_reg(reg_sel[1]),
        .pready(pready),
        .state_access(state_access),
        .busy(busy),
        .error_sticky(error_sticky)
    );

    apb_decoder
    #(
        .USE_APB_FSM(USE_APB_FSM),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .SLAVE_BASE_ADDR(SLAVE_BASE_ADDR),
        .NUM_CTRL_REGS(NUM_CTRL_REGS),
        .NUM_USER_REGS(NUM_USER_REGS)
    )
    apb_decoder_inst
    (
        .access(apb_access),
        .state_access(state_access),
        .paddr(paddr),
        .reg_sel(reg_sel),
        .offset_valid(offset_valid)
    );

    register_bank
    #(
        .USE_APB_FSM(USE_APB_FSM),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_CTRL_REGS(NUM_CTRL_REGS),
        .NUM_USER_REGS(NUM_USER_REGS)
    )
    register_bank_inst
    (
        .clk(clk),
        .rst_n(rst_n),
        .psel(psel),
        .penable(penable),
        .pready(pready),
        .pwrite(pwrite),
        .state_access(state_access),
        .busy(busy),
        .error_sticky(error_sticky),
        .reg_sel(reg_sel),
        .wdata(pwdata),
        .rdata(prdata)
    );
endmodule
