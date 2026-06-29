// Functional coverage collector (Verilator-friendly manual bins)

`ifndef APB_COVERAGE
`define APB_COVERAGE
module apb_coverage
#(
    parameter ADDRESS_WIDTH = 32,
    parameter logic [ADDRESS_WIDTH-1:0] SLAVE_BASE_ADDR = 32'h4000_0000,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    parameter MAX_WAIT_CYCLES = 7,
    parameter real COVERAGE_GOAL = 95.0,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS,
    localparam int NUM_BINS = NUM_REGS + 4 // reg[0:19] + read + write + error + reset
)();
    mailbox #(apb_transaction) cov_mbx;
    bit reg_hit [0:NUM_REGS-1];
    bit read_hit;
    bit write_hit;
    bit error_hit;
    bit reset_hit;
    bit after_reset_sample;

    int hit_count;
    real coverage_pct;

    function automatic int decode_address(input logic [ADDRESS_WIDTH-1:0] paddr);
        logic offset_aligned = paddr[1:0] == 2'b00;
        logic in_window = paddr >= SLAVE_BASE_ADDR && paddr <= SLAVE_BASE_ADDR + NUM_REGS*4 - 1;
        if (offset_aligned && in_window)
            return paddr[7:0] >> 2;
        return -1;
    endfunction

    task notify_reset();
        after_reset_sample = 1;
    endtask

    function automatic void sample_transaction(input apb_transaction trans);
        int addr;
        addr = decode_address(trans.addr);
        if (addr >= 0 && addr < NUM_REGS)
            reg_hit[addr] = 1;
        if (trans.is_read)
            read_hit = 1;
        if (trans.is_write)
            write_hit = 1;
        if (trans.slverr)
            error_hit = 1;
        if (after_reset_sample) begin
            reset_hit = 1;
            after_reset_sample = 0;
        end
    endfunction

    function automatic int count_hits();
        int i, n;
        n = 0;
        for (i = 0; i < NUM_REGS; i = i + 1)
            if (reg_hit[i]) n = n + 1;
        if (read_hit)  n = n + 1;
        if (write_hit) n = n + 1;
        if (error_hit) n = n + 1;
        if (reset_hit) n = n + 1;
        return n;
    endfunction

    function automatic real get_coverage_pct();
        return (real'(count_hits()) / real'(NUM_BINS)) * 100.0;
    endfunction

    function automatic bit coverage_goal_met();
        return get_coverage_pct() >= COVERAGE_GOAL;
    endfunction

    function void set_mailbox(mailbox #(apb_transaction) mb);
        cov_mbx = mb;
    endfunction

    task run();
        apb_transaction trans;
        forever begin
            cov_mbx.get(trans);
            sample_transaction(trans);
        end
    endtask

    task report();
        int i;
        hit_count = count_hits();
        coverage_pct = get_coverage_pct();
        $display("========== FUNCTIONAL COVERAGE SUMMARY ==========");
        $display("  Register bins (%0d):", NUM_REGS);
        for (i = 0; i < NUM_REGS; i = i + 1)
            $display("    reg[%02d]: %s", i, reg_hit[i] ? "HIT" : "MISS");
        $display("  Read transaction:  %s", read_hit ? "HIT" : "MISS");
        $display("  Write transaction: %s", write_hit ? "HIT" : "MISS");
        $display("  Error path:        %s", error_hit ? "HIT" : "MISS");
        $display("  Reset path:        %s", reset_hit ? "HIT" : "MISS");
        $display("  Total: %0d / %0d bins (%.1f%%), goal >= %.1f%%",
                 hit_count, NUM_BINS, coverage_pct, COVERAGE_GOAL);
        if (coverage_goal_met())
            $display("  Coverage goal: PASS");
        else
            $display("  Coverage goal: FAIL");
        $display("=================================================");
    endtask

    task write_report(input string path);
        int fd, i;
        hit_count = count_hits();
        coverage_pct = get_coverage_pct();
        fd = $fopen(path, "w");
        if (fd == 0) begin
            $display("Coverage: failed to open %s", path);
            return;
        end
        $fdisplay(fd, "APB3 Slave Functional Coverage Summary");
        $fdisplay(fd, "======================================");
        $fdisplay(fd, "Register bins (%0d):", NUM_REGS);
        for (i = 0; i < NUM_REGS; i = i + 1)
            $fdisplay(fd, "  reg[%02d]: %s", i, reg_hit[i] ? "HIT" : "MISS");
        $fdisplay(fd, "Read transaction:  %s", read_hit ? "HIT" : "MISS");
        $fdisplay(fd, "Write transaction: %s", write_hit ? "HIT" : "MISS");
        $fdisplay(fd, "Error path:        %s", error_hit ? "HIT" : "MISS");
        $fdisplay(fd, "Reset path:        %s", reset_hit ? "HIT" : "MISS");
        $fdisplay(fd, "");
        $fdisplay(fd, "Total bins hit: %0d / %0d", hit_count, NUM_BINS);
        $fdisplay(fd, "Coverage: %.1f%%", coverage_pct);
        $fdisplay(fd, "Goal: >= %.1f%%", COVERAGE_GOAL);
        $fdisplay(fd, "Result: %s", coverage_goal_met() ? "PASS" : "FAIL");
        $fclose(fd);
    endtask
endmodule
`endif
