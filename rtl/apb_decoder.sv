// APB3 Decoder — address decode and one-hot register select.

module apb_decoder
#(
    parameter USE_APB_FSM = 0,
    parameter ADDRESS_WIDTH = 32,
    parameter [ADDRESS_WIDTH-1:0] SLAVE_BASE_ADDR = 32'h4000_0000,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS,
    localparam REG_IDX_W = $clog2(NUM_REGS + 1)
)
(
    input logic access,
    input logic state_access,
    input [ADDRESS_WIDTH-1:0] paddr,
    output logic [NUM_REGS-1:0] reg_sel,
    output logic offset_valid
);
    logic decode_en;
    logic offset_aligned, in_window;
    logic [REG_IDX_W-1:0] reg_index;

    assign decode_en = (USE_APB_FSM != 0) ? state_access : access;

    always_comb begin
        offset_aligned = (paddr[1:0] == 2'b00);
        in_window = (paddr >= SLAVE_BASE_ADDR)
                 && (paddr <= SLAVE_BASE_ADDR + NUM_REGS * 4 - 1);
        offset_valid = in_window && offset_aligned;
    end

    assign reg_index = paddr[7:2];

    assign reg_sel = (decode_en && offset_valid && (reg_index < NUM_REGS))
                   ? (1'b1 << reg_index)
                   : '0;
endmodule
