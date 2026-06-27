// APB Scoreboard
/*
apb_scoreboard.sv — for Verilator use a module with tasks (or package); Questa later can be a class:
*/

`ifndef APB_SCOREBOARD
`define APB_SCOREBOARD
module apb_scoreboard
#(
    parameter bit USE_APB_FSM = 1'b0,
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter logic [ADDRESS_WIDTH-1:0] SLAVE_BASE_ADDR = 32'h4000_0000,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)
(
    mailbox #(apb_transaction) mon_mbx
);
    bit verbose = 1;
    // REG_BANK
    logic [DATA_WIDTH-1:0] reg_bank [0:NUM_REGS-1];
    int err_count = 0;
    
    // error count
    function int get_error_count();
        return err_count;
    endfunction
    // reset model
    task reset_model();
        foreach(reg_bank[i]) reg_bank[i] = '0;
    endtask
    // Address decoder
    function automatic int decode_address(input logic [ADDRESS_WIDTH-1:0] paddr);
        logic offset_aligned = paddr[1:0] == 2'b00;
        logic address_in_window = paddr >= SLAVE_BASE_ADDR && paddr <= SLAVE_BASE_ADDR + NUM_REGS*4 - 1;
        logic offset_valid = offset_aligned && address_in_window;
        if (offset_valid) begin
            return paddr[7:0] >> 2;
        end
        else begin
            return -1; // Invalid address or not in window or not aligned
        end
    endfunction

    // slave error checker
    function automatic bit check_slave_error(input int addr, input bit is_write);
        if (addr < 0) return 1; // Invalid address
        if (addr < NUM_REGS) begin
            if (is_write && addr == 1) return 1; // Write to status register is not allowed
            else return 0;
        end
        else return 1; // Invalid address or not in window or not aligned
    endfunction

    // Run task
    task run();
        apb_transaction trans;
        int addr;
        bit error;

        // initializing the model
        reset_model();
        err_count = 0;
        
        forever begin
            mon_mbx.get(trans);
            addr = decode_address(trans.addr);
            error = check_slave_error(addr, trans.is_write);

            // 1. Check SLVERR
            if (trans.slverr !== error) begin
                if(verbose) $display("Scoreboard: SLVERR mismatch: dut_addr %h sb_addr %h exp_slverr %b got_slverr %b", trans.addr, addr, error, trans.slverr);
                err_count++;
            end

            // 2. Legal beat - update / compare data
            if (!error ) begin
                if (trans.is_write && addr != -1 && addr != 1) begin
                    reg_bank[addr] = trans.wdata;
                    if(verbose) $display("Scoreboard: Write to register %h: %h", addr, trans.wdata);
                end
                else if (trans.is_read && trans.ready) begin
                    if (USE_APB_FSM && addr == 1) begin
                        if (verbose)
                            $display("Scoreboard: STATUS read (dynamic): DATA: %h", trans.rdata);
                    end
                    else if (trans.rdata !== reg_bank[addr]) begin
                        $display("Scoreboard: Read mismatch: dut_addr %h sb_addr %h exp_data %h got_data %h", trans.addr, addr, reg_bank[addr], trans.rdata);
                        err_count++;
                    end
                    else if (verbose) begin
                        $display("Scoreboard: Read from register %h: DATA: %h is OKAY!", addr, trans.rdata);
                    end
                end
            end
        end
    endtask
endmodule
`endif // APB_SCOREBOARD
