// APB3 Decoder
// Address decode and register select. When USE_APB_FSM=1, decode during ACCESS only
// and optionally latch address during SETUP.

module apb_decoder
#(
    parameter bit USE_APB_FSM = 1'b0,
    parameter ADDRESS_WIDTH = 32,
    parameter logic [ADDRESS_WIDTH-1:0] SLAVE_BASE_ADDR = 32'h4000_0000,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)
(
    input logic access,
    input logic state_access,
    input [ADDRESS_WIDTH-1:0] paddr,
    output logic [NUM_REGS-1:0] reg_sel,
    output logic offset_valid
);
    byte unsigned i;

    logic decode_en;
    logic offset_aligned, in_window;

    // Master holds paddr stable through SETUP and ACCESS (APB3)
    assign decode_en = USE_APB_FSM ? state_access : access;

    always_comb begin
        offset_aligned = paddr[1:0] == 2'b00;
        in_window = paddr >= SLAVE_BASE_ADDR
                 && paddr <= SLAVE_BASE_ADDR + NUM_REGS*4 - 1;
        offset_valid = in_window && offset_aligned;
    end

    always_comb begin
        reg_sel = '0;
        if (decode_en) begin
            if (offset_valid) begin
                for (i = 0; i < NUM_CTRL_REGS; i = i + 1)
                    reg_sel[i] = paddr[7:0] == 8'h00 + 4 * i;
                for (i = 0; i < NUM_USER_REGS; i = i + 1)
                    reg_sel[NUM_CTRL_REGS + i] = paddr[7:0] == 8'h10 + 4 * i;
            end
        end
    end
endmodule
