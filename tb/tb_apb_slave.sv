/*
Step 0.1 — Create minimal tb_apb_slave.sv
Clock generator (forever #5 clk = ~clk)
Reset (rst_n low 3 cycles, then high)
Instantiate apb_slave_top with correct params (NUM_CTRL_REGS=4, NUM_USER_REGS=16)
One initial block with inline APB write/read (no driver file yet)
$finish(0) on pass, $finish(1) on fail
Timeout guard (#1_000_000; $finish(1))

Step 0.2 — APB 2-cycle protocol (memorize this)
Cycle	PSEL	PENABLE	PWRITE	Action
Setup
1
0
R/W
Drive paddr, pwdata if write
Access
1
1
R/W
Wait pready==1, sample prdata/pslverr
*/

`timescale 1ns/1ps

module tb_apb_slave;
    // Parameters
    localparam ADDRESS_WIDTH = 32;
    localparam SLAVE_BASE_ADDR = 32'h4000_0000;
    localparam DATA_WIDTH = 32;
    localparam MAX_WAIT_CYCLES = 7;
    localparam DEFAULT_WAIT_CYCLES = 2;
    localparam USE_APB_FSM = 1'b1;
    localparam NUM_CTRL_REGS = 4;
    localparam NUM_USER_REGS = 16;
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS;
    localparam PERIOD = 10; // 10ns period => 100MHz clock
    localparam HALF_PERIOD = PERIOD/2;
    
    function automatic logic [ADDRESS_WIDTH-1:0] get_address(input int reg_index);
        return SLAVE_BASE_ADDR + reg_index * 4;
    endfunction

    function automatic bit in_slave_window(input logic [ADDRESS_WIDTH-1:0] addr);
        return addr >= SLAVE_BASE_ADDR && addr < SLAVE_BASE_ADDR + NUM_REGS*4;
    endfunction

    function automatic bit is_writable(input int reg_index);
        return (reg_index >= 0) && (reg_index < NUM_REGS) && (reg_index != 1);
    endfunction

    logic [$clog2(MAX_WAIT_CYCLES+1)-1:0] num_wait_cycles_cfg = DEFAULT_WAIT_CYCLES;

    // Apply a new wait-cycle setting only while the bus is idle
    task automatic set_wait_cycles(input int n);
        num_wait_cycles_cfg = n[$clog2(MAX_WAIT_CYCLES+1)-1:0];
        repeat (2) @(posedge vif.pclk);
    endtask

    // Write/read CTRL for the current wait-cycle setting
    task automatic wait_cycle_write_read_smoke(
        input int wait_n,
        input logic [DATA_WIDTH-1:0] data
    );
        set_wait_cycles(wait_n);
        drv.apb_write(get_address(0), data, slverr);
        if (slverr) begin
            $display("Wait-cycle smoke failed on write: wait=%0d", wait_n);
            $finish(1);
        end
        drv.apb_read(get_address(0), rdata, slverr);
        if (slverr) begin
            $display("Wait-cycle smoke failed on read: wait=%0d", wait_n);
            $finish(1);
        end
        if (rdata !== data) begin
            $display("Wait-cycle smoke data mismatch: wait=%0d exp=%h got=%h", wait_n, data, rdata);
            $finish(1);
        end
    endtask
    
    // Instantiate the apb_slave_top module
    apb_slave_top
    #(
        .USE_APB_FSM(USE_APB_FSM),
        .MAX_WAIT_CYCLES(MAX_WAIT_CYCLES),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SLAVE_BASE_ADDR(SLAVE_BASE_ADDR),
        .NUM_CTRL_REGS(NUM_CTRL_REGS),
        .NUM_USER_REGS(NUM_USER_REGS)
    )
    dut
    (
        .clk(vif.pclk),
        .rst_n(vif.rst_n),
        .num_wait_cycles(num_wait_cycles_cfg),
        .psel(vif.psel),
        .penable(vif.penable),
        .pwrite(vif.pwrite),
        .paddr(vif.paddr),
        .pwdata(vif.pwdata),
        .pslverr(vif.pslverr),
        .pready(vif.pready),
        .prdata(vif.prdata)
    );
    
    // Instantiate the apb_if interface and direct interface to the DUT
    apb_if #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) vif();

    // Instantiate the apb_driver module
    apb_driver #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) drv(.vif(vif)); // Direct interface to the DUT
    
    // Instantiate mailbox for monitor and coverage
    mailbox #(apb_transaction) mon_mbx = new();
    mailbox #(apb_transaction) cov_mbx = new();
    
    // Instantiate the apb_monitor module
    apb_monitor #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mon(.vif(vif), .mon_mbx(mon_mbx), .cov_mbx(cov_mbx));

    apb_coverage #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .SLAVE_BASE_ADDR(SLAVE_BASE_ADDR),
        .NUM_CTRL_REGS(NUM_CTRL_REGS),
        .NUM_USER_REGS(NUM_USER_REGS),
        .MAX_WAIT_CYCLES(MAX_WAIT_CYCLES),
        .COVERAGE_GOAL(95.0)
    ) cov(.cov_mbx(cov_mbx));

    apb_protocol_checker #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) proto_chk(.vif(vif));

    `ifndef VERILATOR
    apb_assertions #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) assert_inst (
        .vif(vif),
        .offset_valid(dut.apb_decoder_inst.offset_valid)
    );
    `endif
    
    // Instantiate the apb_scoreboard module
    apb_scoreboard #(
        .USE_APB_FSM(USE_APB_FSM),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_CTRL_REGS(NUM_CTRL_REGS),
        .NUM_USER_REGS(NUM_USER_REGS)
    ) sb(.mon_mbx(mon_mbx)); // Scoreboard to the DUT


    // Clock generator
    initial begin
        vif.pclk = 0;
        forever #HALF_PERIOD vif.pclk = ~vif.pclk; // Toggle the clock
    end

    logic [DATA_WIDTH-1:0] rdata;
    logic slverr;

    // Drain mailbox / let scoreboard catch up
    task wait_sb(input int cycles = 20);
        repeat (cycles) @(posedge vif.pclk);
    endtask

    bit regression_pass = 1;

    task automatic write_regression_report(input string path);
        int fd;
        fd = $fopen(path, "w");
        if (fd == 0) begin
            $display("Failed to open regression report: %s", path);
            return;
        end
        $fdisplay(fd, "APB3 Slave Regression Report");
        $fdisplay(fd, "=============================");
        $fdisplay(fd, "Date: simulation end");
        $fdisplay(fd, "Simulator: Verilator");
        $fdisplay(fd, "USE_APB_FSM: %0d", USE_APB_FSM);
        $fdisplay(fd, "");
        $fdisplay(fd, "Tests: %s", regression_pass ? "ALL PASSED" : "FAILED");
        $fdisplay(fd, "Scoreboard errors: %0d", sb.err_count);
        $fdisplay(fd, "Protocol violations: %0d", proto_chk.get_violation_count());
        `ifdef VERILATOR
        $fdisplay(fd, "SVA assertions: N/A (Verilator — use apb_protocol_checker)");
        `else
        $fdisplay(fd, "SVA assertion failures: %0d", assert_inst.get_failure_count());
        `endif
        $fdisplay(fd, "Functional coverage: %.1f%% (goal >= 95%%)", cov.get_coverage_pct());
        $fdisplay(fd, "Coverage goal: %s", cov.coverage_goal_met() ? "PASS" : "FAIL");
        $fdisplay(fd, "");
        $fdisplay(fd, "Exit criteria:");
        $fdisplay(fd, "  [ %s ] No scoreboard mismatches", sb.err_count == 0 ? "PASS" : "FAIL");
        $fdisplay(fd, "  [ %s ] No protocol violations", proto_chk.get_violation_count() == 0 ? "PASS" : "FAIL");
        $fdisplay(fd, "  [ %s ] Coverage >= 95%%", cov.coverage_goal_met() ? "PASS" : "FAIL");
        $fdisplay(fd, "");
        $fdisplay(fd, "Overall: %s", regression_pass ? "PASS" : "FAIL");
        $fclose(fd);
    endtask

    // Per-test pass check (delta on err_count)
    task check_test(input string name, input int err_before, input int drain_cycles = 20);
        wait_sb(drain_cycles);
        if (sb.err_count > err_before) begin
            regression_pass = 0;
            $fatal("Test failed: %s: new errors: %d", name, sb.err_count - err_before);
            $finish(1); // Test failed, finish simulation
        end
        else begin
            $display("Test passed: %s: Scoreboard passed", name);
        end
    endtask

    int err_before;

    // Test sequence; run the monitor in parallel with the test sequence
    initial begin
        fork
            mon.monitor_apb();
            sb.run();
            cov.run();
        join_none;
        
        err_before = sb.get_error_count();
        // TEST 1 RESET - Verify all registers reset correctly.
        test_reset(); err_before = sb.get_error_count();
        // TEST 2 SINGLE WRITE - Write one register. Read back and compare.
        test_single_write(); err_before = sb.get_error_count();
        // TEST 3 FULL REGISTER SWEEP - Write/read every register.
        test_full_register_sweep(); err_before = sb.get_error_count();
        // TEST 4 BACK-TO-BACK WRITES - 100 consecutive writes.
        test_back_to_back_writes(); err_before = sb.get_error_count();
        // TEST 5 BACK-TO-BACK READS - 100 consecutive reads.
        test_back_to_back_reads(); err_before = sb.get_error_count();
        // TEST 6 ILLEGAL ADDRESS ACCESS - Verify PSLVERR assertion.
        test_illegal_address_access(); err_before = sb.get_error_count();
        // TEST 7 RANDOM READ/WRITE - 1000+ random transactions.
        test_random_read_write(); err_before = sb.get_error_count();
        // TEST 8 WAIT CYCLE SWEEP - num_wait_cycles 0..7
        test_wait_cycle_sweep(); err_before = sb.get_error_count();
        // TEST 9 RANDOM WAIT CYCLES - 10 random wait settings
        test_random_wait_cycles(); err_before = sb.get_error_count();
        if (USE_APB_FSM)
            test_apb_fsm_status(); err_before = sb.get_error_count();

        // M3: drain coverage/scoreboard and generate reports
        wait_sb(100);
        if (proto_chk.get_violation_count() > 0)
            regression_pass = 0;
        `ifndef VERILATOR
        if (assert_inst.get_failure_count() > 0)
            regression_pass = 0;
        `endif
        if (!cov.coverage_goal_met())
            regression_pass = 0;

        cov.report();
        cov.write_report("../reports/coverage_summary.txt");
        write_regression_report("../reports/regression_report.txt");
        
        if(regression_pass) begin
            $display("================================================");
            $display("==================All tests passed==============");
            $display("================================================");
            $finish(0); // All tests passed, finish simulation
        end
        else begin
            $display("================================================");
            $display("==================Regression failed==============");
            $display("================================================");
            $finish(1); // Regression failed, finish simulation
        end
    end
    

    // Test 1: RESET - Verify all registers reset correctly.
    task automatic test_reset();
        int err_before = sb.get_error_count();
        int i;
        $display("==================Test 1: RESET==============");
        drv.reset_dut();
        sb.reset_model();
        cov.notify_reset();
        for(i = 0; i < NUM_REGS; i++) begin
            drv.apb_read(get_address(i), rdata, slverr);
            if(slverr) begin
                $display("Test failed: pslverr asserted @ register %0d", i);
                $finish(1); // Test failed, finish simulation
            end
        end
        check_test("TEST 1: RESET", err_before);
    endtask

    // Test 2: SINGLE WRITE - Write one register. Read back and compare.
    task automatic test_single_write();
        logic [DATA_WIDTH-1:0] data = 32'h3333_9999;
        int err_before = sb.get_error_count();
        $display("==================Test 2: SINGLE WRITE==============");
        drv.apb_write(get_address(0), data, slverr);
        if(slverr) $finish(1); // Test failed, finish simulation
        drv.apb_read(get_address(0), rdata, slverr);
        if(slverr) $finish(1); // Test failed, finish simulation
        check_test("TEST 2: SINGLE WRITE", err_before);
    endtask

    // Test 3: FULL REGISTER SWEEP - Write/read every register.
    task automatic test_full_register_sweep();
        int err_before = sb.get_error_count();
        int i;
        $display("==================Test 3: FULL REGISTER SWEEP==============");
        // Write Sweep except Status Register
        for(i = 0; i < NUM_REGS; i++) begin
            if(is_writable(i)) begin
                drv.apb_write(get_address(i), 32'h3939_3939 | i, slverr);
                if(slverr) $finish(1); // Test failed, finish simulation
            end
            else continue;
        end
        // Read Sweep all registers
        for(i = 0; i < NUM_REGS; i++) begin
            drv.apb_read(get_address(i), rdata, slverr);
            if(slverr) $finish(1); // Test failed, finish simulation
        end
        check_test("TEST 3: FULL REGISTER SWEEP", err_before);
    endtask

    // Test 4: BACK-TO-BACK WRITES - 100 consecutive writes.
    task automatic test_back_to_back_writes();
        int err_before = sb.get_error_count();
        int i,j;
        $display("==================Test 4: BACK-TO-BACK WRITES==============");
        // Quiet mode for bulk traffic
        sb.verbose = 0;
        mon.verbose = 0;
        drv.verbose = 0;
        for(i = 0; i < 100; i++) begin
            j = i % NUM_REGS;
            if (j == 1) j = 2; // Skipping Write to Status Register
            drv.apb_write(get_address(j), 32'h3939_3939 | j, slverr);
            if(slverr) $finish(1); // Test failed, finish simulation
        end
        // Restore verbose mode
        sb.verbose = 1;
        mon.verbose = 1;
        drv.verbose = 1;
        check_test("TEST 4: BACK-TO-BACK WRITES", err_before);
    endtask

    // Test 5: BACK-TO-BACK READS - 100 consecutive reads.
    task automatic test_back_to_back_reads();
        int err_before = sb.get_error_count();
        int i,j;
        $display("==================Test 5: BACK-TO-BACK READS==============");
        // Quiet mode for bulk traffic
        sb.verbose = 0;
        mon.verbose = 0;
        drv.verbose = 0;
        for(i = 0; i < 100; i++) begin
            j = i % NUM_REGS;
            drv.apb_read(get_address(j), rdata, slverr);
            if(slverr) $finish(1); // Test failed, finish simulation
        end
        // Restore verbose mode
        sb.verbose = 1;
        mon.verbose = 1;
        drv.verbose = 1;
        check_test("TEST 5: BACK-TO-BACK READS", err_before);
    endtask

    // Test 6: ILLEGAL ADDRESS ACCESS - Verify PSLVERR assertion.
    task test_illegal_address_access();
        int err_before = sb.get_error_count();
        $display("==================Test 6: ILLEGAL ADDRESS ACCESS==============");
        drv.apb_write(SLAVE_BASE_ADDR + 32'h6c, 32'h0, slverr); // outside and aligned with register window address range
        drv.apb_write(SLAVE_BASE_ADDR + 32'h6a, 32'h0, slverr); // outside and not aligned with register window address range
        drv.apb_read(SLAVE_BASE_ADDR + 32'h02, rdata, slverr); // inside and not aligned with register window address range
        drv.apb_write(SLAVE_BASE_ADDR + 32'h05, 32'h0, slverr); // inside and not aligned with register window address range
        drv.apb_write(SLAVE_BASE_ADDR + 32'h04, 32'h0, slverr); 
        // inside and aligned with register window address range but write to status register should not be allowed
        // Driver sees error; Scoreboard sees error; Test passes
        check_test("TEST 6: ILLEGAL ADDRESS ACCESS", err_before);
    endtask // Test 6: ILLEGAL ADDRESS ACCESS - Verify PSLVERR assertion.

    // Test 7: RANDOM READ/WRITE - 1000+ random transactions.
    task automatic test_random_read_write();
        int err_before = sb.get_error_count();
        int i;
        logic [ADDRESS_WIDTH-1:0] addr;
        logic [DATA_WIDTH-1:0] wdata;
        bit write;
        $display("==================Test 7: RANDOM READ/WRITE==============");
        // Quiet mode for bulk traffic
        sb.verbose = 0;
        mon.verbose = 0;
        drv.verbose = 0;
        drv.quiet_errors = 1;
        for(i = 0; i < 1111; i++) begin // Atleast 1111 random transactions inside the slave window
            addr = SLAVE_BASE_ADDR + $urandom_range(0, NUM_REGS*4 - 1);
            wdata = $urandom;
            write = $urandom & 1'b1;
            if (write) drv.apb_write(addr, wdata, slverr);
            else drv.apb_read(addr, rdata, slverr);
        end
        for(i = 0; i < 1111; i++) begin // Atleast 1111 random transactions in whole address space
            addr = $urandom_range(0, 2**ADDRESS_WIDTH - 1);
            wdata = $urandom;
            write = $urandom & 1'b1;
            if (write) drv.apb_write(addr, wdata, slverr);
            else drv.apb_read(addr, rdata, slverr);
        end
        // Restore verbose mode
        drv.quiet_errors = 0;
        sb.verbose = 1;
        mon.verbose = 1;
        drv.verbose = 1;
        check_test("TEST 7: RANDOM READ/WRITE", err_before, 5*2222);
    endtask

    // Test 8: WAIT CYCLE SWEEP - sweep num_wait_cycles 0 through 7
    task automatic test_wait_cycle_sweep();
        int err_before = sb.get_error_count();
        int w;
        $display("==================Test 8: WAIT CYCLE SWEEP==============");
        sb.verbose = 0;
        mon.verbose = 0;
        drv.verbose = 0;
        for (w = 0; w <= MAX_WAIT_CYCLES; w++) begin
            wait_cycle_write_read_smoke(w, 32'h8000_0000 | w);
            $display("  wait_cycles=%0d OK", w);
        end
        sb.verbose = 1;
        mon.verbose = 1;
        drv.verbose = 1;
        set_wait_cycles(DEFAULT_WAIT_CYCLES);
        check_test("TEST 8: WAIT CYCLE SWEEP", err_before);
    endtask

    // Test 9: RANDOM WAIT CYCLES - 10 iterations with random wait setting
    task automatic test_random_wait_cycles();
        int err_before = sb.get_error_count();
        int i, w;
        logic [DATA_WIDTH-1:0] data;
        $display("==================Test 9: RANDOM WAIT CYCLES==============");
        sb.verbose = 0;
        mon.verbose = 0;
        drv.verbose = 0;
        for (i = 0; i < 10; i++) begin
            w = $urandom_range(0, MAX_WAIT_CYCLES);
            data = $urandom;
            wait_cycle_write_read_smoke(w, data);
            $display("  iter=%0d wait_cycles=%0d OK", i, w);
        end
        sb.verbose = 1;
        mon.verbose = 1;
        drv.verbose = 1;
        set_wait_cycles(DEFAULT_WAIT_CYCLES);
        check_test("TEST 9: RANDOM WAIT CYCLES", err_before);
    endtask

    // Test 10: APB FSM — STATUS busy/error reflect protocol state (USE_APB_FSM=1 only)
    task automatic test_apb_fsm_status();
        int err_before = sb.get_error_count();
        $display("==================Test 10: APB FSM STATUS==============");
        drv.reset_dut();
        sb.reset_model();
        // Read STATUS — error bit must be 0 (busy may be 1 during the read transfer itself)
        drv.apb_read(get_address(1), rdata, slverr);
        if (slverr || rdata[1] !== 1'b0) begin
            $display("Test 10 fail: STATUS error after reset exp 0 got %h slverr %b", rdata, slverr);
            $finish(1);
        end
        // Illegal write sets error sticky in STATUS
        drv.apb_write(get_address(1), 32'h0, slverr);
        if (!slverr) begin
            $display("Test 10 fail: expected SLVERR on STATUS write");
            $finish(1);
        end
        drv.apb_read(get_address(1), rdata, slverr);
        if (slverr || rdata[1] !== 1'b1) begin
            $display("Test 10 fail: STATUS error bit exp 1 got %h", rdata);
            $finish(1);
        end
        // Successful legal write clears error bit
        drv.apb_write(get_address(0), 32'h1, slverr);
        if (slverr) $finish(1);
        drv.apb_read(get_address(1), rdata, slverr);
        if (slverr || rdata[1] !== 1'b0) begin
            $display("Test 10 fail: STATUS error cleared exp 0 got %h", rdata);
            $finish(1);
        end
        check_test("TEST 10: APB FSM STATUS", err_before);
    endtask

    // Timeout guard
    initial begin
        #50_000_000; // 50ms timeout
        $display("TIMEOUT: Simulation timed out after 50ms");
        $finish(1); // Timeout, finish simulation
    end

    // Assertions: apb_protocol_checker (Verilator) + apb_assertions.sv (Questa/Xcelium)
    `ifdef VERILATOR
    initial $display("SVA module disabled — using apb_protocol_checker for Verilator");
    `endif
endmodule
