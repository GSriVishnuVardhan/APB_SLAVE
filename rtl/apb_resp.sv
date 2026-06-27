// APB Response Logic
// APB3: PREADY high only on final ACCESS cycle (after num_wait_cycles low-ready cycles).
// Optional USE_APB_FSM: registered IDLE / SETUP / ACCESS state machine (spec).

module apb_response_logic
#(
    parameter bit USE_APB_FSM = 1'b0,
    parameter MAX_WAIT_CYCLES = 7
)
(
    input logic [$clog2(MAX_WAIT_CYCLES+1)-1:0] num_wait_cycles,
    input pclk, rst_n,
    input psel, penable,
    input apb_access, write, offset_valid, status_reg,
    output logic pslverr, pready,
    output logic state_access,
    output logic busy,
    output logic error_sticky
);

    typedef enum logic [1:0] {
        ST_IDLE   = 2'b00,
        ST_SETUP  = 2'b01,
        ST_ACCESS = 2'b10
    } apb_state_e;

    apb_state_e state, next_state;

    logic [$clog2(MAX_WAIT_CYCLES+1)-1:0] wait_count;
    logic wait_done;
    logic transfer_active;
    logic pready_comb;
    logic pslverr_comb;

    // Registered APB phase FSM (IDLE / SETUP / ACCESS)
    always_comb begin
        next_state = state;
        unique case (state)
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
        else if (USE_APB_FSM)
            state <= next_state;
    end

    assign state_access    = USE_APB_FSM ? (psel & penable) : apb_access;
    assign transfer_active = state_access;
    assign busy            = USE_APB_FSM ? (state != ST_IDLE) : 1'b0;

    // SLVERR & PREADY — high only on the completion ACCESS cycle
    always_comb begin
        if (transfer_active && wait_done) begin
            if (!offset_valid)
                pslverr_comb = 1;
            else
                pslverr_comb = write && status_reg ? 1 : 0;
            pready_comb = 1;
        end
        else begin
            pslverr_comb = 0;
            pready_comb = 0;
        end
    end

    assign pslverr = pslverr_comb;
    assign pready  = pready_comb;

    // Wait counter — active during ACCESS (including wait states)
    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            wait_count <= '0;
        else if (!transfer_active)
            wait_count <= '0;
        else if (num_wait_cycles > 0 && !wait_done)
            wait_count <= wait_count + 1;
    end

    always_comb begin
        if (transfer_active) begin
            if (num_wait_cycles > 0)
                wait_done = (wait_count == num_wait_cycles);
            else
                wait_done = 1;
        end
        else
            wait_done = 0;
    end

    // Latched error flag for STATUS[1] when FSM enabled (last completed beat)
    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            error_sticky <= 1'b0;
        else if (!USE_APB_FSM)
            error_sticky <= 1'b0;
        else if (transfer_active && wait_done)
            error_sticky <= pslverr_comb;
    end

endmodule
