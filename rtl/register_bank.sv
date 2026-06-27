// APB3 Register Bank
// When USE_APB_FSM=1: phase-gated strobes; STATUS read returns live busy/error.

module register_bank
#(
    parameter bit USE_APB_FSM = 1'b0,
    parameter DATA_WIDTH = 32,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)
(
    input clk, rst_n,
    input psel, penable, pready, pwrite,
    input logic state_access,
    input logic busy,
    input logic error_sticky,
    input [NUM_REGS-1:0] reg_sel,
    input [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);
    logic phase_ok;
    logic apb_write;
    logic apb_read;

    logic [DATA_WIDTH-1:0] ctrl_register_bank [0:NUM_CTRL_REGS-1];
    logic [DATA_WIDTH-1:0] user_register_bank [0:NUM_USER_REGS-1];

    integer i;

    assign phase_ok  = USE_APB_FSM ? state_access : (psel & penable);
    assign apb_write = phase_ok & pready & pwrite;
    assign apb_read  = phase_ok & pready & ~pwrite;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_CTRL_REGS; i = i + 1)
                ctrl_register_bank[i] <= '0;
            for (i = 0; i < NUM_USER_REGS; i = i + 1)
                user_register_bank[i] <= '0;
        end
        else if (apb_write) begin
            for (i = 0; i < NUM_CTRL_REGS; i = i + 1) begin
                if (reg_sel[i] && i != 1)
                    ctrl_register_bank[i] <= wdata;
            end
            for (i = NUM_CTRL_REGS; i < NUM_REGS; i = i + 1)
                if (reg_sel[i])
                    user_register_bank[i - NUM_CTRL_REGS] <= wdata;
        end
    end

    always_comb begin
        rdata = '0;
        if (apb_read && |reg_sel) begin
            for (i = 0; i < NUM_CTRL_REGS; i = i + 1) begin
                if (reg_sel[i]) begin
                    if (USE_APB_FSM && i == 1)
                        rdata = {30'b0, error_sticky, busy};
                    else
                        rdata = ctrl_register_bank[i];
                end
            end
            for (i = NUM_CTRL_REGS; i < NUM_REGS; i = i + 1)
                if (reg_sel[i])
                    rdata = user_register_bank[i - NUM_CTRL_REGS];
        end
    end
endmodule
