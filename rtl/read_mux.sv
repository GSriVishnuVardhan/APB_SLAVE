// Read data multiplexer — selects register storage or live STATUS fields.
// Packed register buses + generate mux (Yosys-friendly).

module read_mux
#(
    parameter USE_APB_FSM = 0,
    parameter DATA_WIDTH = 32,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)
(
    input  logic                              apb_read,
    input  logic [NUM_REGS-1:0]               reg_sel,
    input  logic [NUM_CTRL_REGS*DATA_WIDTH-1:0] ctrl_regs_flat,
    input  logic [NUM_USER_REGS*DATA_WIDTH-1:0] user_regs_flat,
    input  logic                              busy,
    input  logic                              error_sticky,
    output logic [DATA_WIDTH-1:0]             rdata
);
    logic [DATA_WIDTH-1:0] reg_data [0:NUM_REGS-1];
    logic [DATA_WIDTH-1:0] masked [0:NUM_REGS-1];
    logic [DATA_WIDTH-1:0] rdata_or;

    genvar g;

    generate
        for (g = 0; g < NUM_CTRL_REGS; g = g + 1) begin : gen_ctrl_data
            assign reg_data[g] = (USE_APB_FSM != 0 && g == 1)
                               ? {30'b0, error_sticky, busy}
                               : ctrl_regs_flat[g*DATA_WIDTH +: DATA_WIDTH];
        end
        for (g = 0; g < NUM_USER_REGS; g = g + 1) begin : gen_user_data
            assign reg_data[NUM_CTRL_REGS + g] = user_regs_flat[g*DATA_WIDTH +: DATA_WIDTH];
        end
        for (g = 0; g < NUM_REGS; g = g + 1) begin : gen_mask
            assign masked[g] = {DATA_WIDTH{(apb_read & reg_sel[g])}} & reg_data[g];
        end
        if (NUM_REGS == 20) begin : gen_or20
            assign rdata_or = masked[0] | masked[1] | masked[2] | masked[3] | masked[4]
                            | masked[5] | masked[6] | masked[7] | masked[8] | masked[9]
                            | masked[10] | masked[11] | masked[12] | masked[13] | masked[14]
                            | masked[15] | masked[16] | masked[17] | masked[18] | masked[19];
        end
    endgenerate

    assign rdata = apb_read ? rdata_or : '0;
endmodule
