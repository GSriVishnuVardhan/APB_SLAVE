// APB Response Logic
// APB3: PREADY high only on final ACCESS cycle (after num_wait_cycles low-ready cycles).
// Optional USE_APB_FSM: registered IDLE / SETUP / ACCESS state machine (spec).

module apb_response_logic
#(
    parameter USE_APB_FSM = 0,
    parameter MAX_WAIT_CYCLES = 7,
    localparam WAIT_W = $clog2(MAX_WAIT_CYCLES + 1)
)
(
    input  logic [WAIT_W-1:0] num_wait_cycles,
    input  logic pclk,
    input  logic rst_n,
    input  logic psel,
    input  logic penable,
    input  logic apb_access,
    input  logic write,
    input  logic offset_valid,
    input  logic status_reg,
    output logic pslverr,
    output logic pready,
    output logic state_access,
    output logic busy,
    output logic error_sticky
);

    localparam logic [1:0] ST_IDLE   = 2'b00;
    localparam logic [1:0] ST_SETUP  = 2'b01;
    localparam logic [1:0] ST_ACCESS = 2'b10;

    logic [1:0] state, next_state;

    logic [WAIT_W-1:0] wait_count;
    logic wait_done;
    logic transfer_active;
    logic pready_comb;
    logic pslverr_comb;

    always_comb begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (psel && !penable)
                    next_state = ST_SETUP;
                else if (psel && penable)
                    next_state = ST_ACCESS;
            end
            ST_SETUP: begin
                if (!psel)
                    next_state = ST_IDLE;
                else if (penable)
                    next_state = ST_ACCESS;
            end
            ST_ACCESS: begin
                if (!psel)
                    next_state = ST_IDLE;
                else if (!penable)
                    next_state = ST_SETUP;
            end
            default: next_state = ST_IDLE;
        endcase
    end

    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else if (USE_APB_FSM != 0)
            state <= next_state;
    end

    assign state_access    = (USE_APB_FSM != 0) ? (psel & penable) : apb_access;
    assign transfer_active = state_access;
    assign busy            = (USE_APB_FSM != 0) ? (state != ST_IDLE) : 1'b0;

    always_comb begin
        if (transfer_active && wait_done) begin
            pslverr_comb = (!offset_valid) || (write && status_reg);
            pready_comb  = 1'b1;
        end
        else begin
            pslverr_comb = 1'b0;
            pready_comb  = 1'b0;
        end
    end

    assign pslverr = pslverr_comb;
    assign pready  = pready_comb;

    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            wait_count <= '0;
        else if (!transfer_active)
            wait_count <= '0;
        else if (num_wait_cycles > 0 && !wait_done)
            wait_count <= wait_count + 1'b1;
    end

    always_comb begin
        if (transfer_active)
            wait_done = (num_wait_cycles == 0) || (wait_count == num_wait_cycles);
        else
            wait_done = 1'b0;
    end

    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            error_sticky <= 1'b0;
        else if (USE_APB_FSM == 0)
            error_sticky <= 1'b0;
        else if (transfer_active && wait_done)
            error_sticky <= pslverr_comb;
    end

endmodule
