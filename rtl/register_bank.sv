// APB3 register storage — write port only; read path via read_mux.

module register_bank
#(
    parameter USE_APB_FSM = 0,
    parameter DATA_WIDTH = 32,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)
(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   psel,
    input  logic                   penable,
    input  logic                   pready,
    input  logic                   pwrite,
    input  logic                   state_access,
    input  logic                   busy,
    input  logic                   error_sticky,
    input  logic [NUM_REGS-1:0]    reg_sel,
    input  logic [DATA_WIDTH-1:0]  wdata,
    output logic [DATA_WIDTH-1:0]  rdata
);
    logic phase_ok;
    logic apb_write;
    logic apb_read;

    logic [DATA_WIDTH-1:0] ctrl_register_bank [0:NUM_CTRL_REGS-1];
    logic [DATA_WIDTH-1:0] user_register_bank [0:NUM_USER_REGS-1];
    logic [NUM_CTRL_REGS*DATA_WIDTH-1:0] ctrl_regs_flat;
    logic [NUM_USER_REGS*DATA_WIDTH-1:0]  user_regs_flat;

    integer i;
    genvar g;

    generate
        for (g = 0; g < NUM_CTRL_REGS; g = g + 1) begin : gen_ctrl_flat
            assign ctrl_regs_flat[g*DATA_WIDTH +: DATA_WIDTH] = ctrl_register_bank[g];
        end
        for (g = 0; g < NUM_USER_REGS; g = g + 1) begin : gen_user_flat
            assign user_regs_flat[g*DATA_WIDTH +: DATA_WIDTH] = user_register_bank[g];
        end
    endgenerate

    assign phase_ok  = (USE_APB_FSM != 0) ? state_access : (psel & penable);
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

    read_mux #(
        .USE_APB_FSM   (USE_APB_FSM),
        .DATA_WIDTH    (DATA_WIDTH),
        .NUM_CTRL_REGS (NUM_CTRL_REGS),
        .NUM_USER_REGS (NUM_USER_REGS)
    ) read_mux_inst (
        .apb_read        (apb_read),
        .reg_sel         (reg_sel),
        .ctrl_regs_flat  (ctrl_regs_flat),
        .user_regs_flat  (user_regs_flat),
        .busy            (busy),
        .error_sticky    (error_sticky),
        .rdata           (rdata)
    );
endmodule
