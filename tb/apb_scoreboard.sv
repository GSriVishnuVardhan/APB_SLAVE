// Scoreboard — compares DUT transactions against golden reference model.

`ifndef APB_SCOREBOARD
`define APB_SCOREBOARD

import apb_ref_model_pkg::*;

module apb_scoreboard #(
    parameter bit USE_APB_FSM = 1'b0,
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter logic [ADDRESS_WIDTH-1:0] SLAVE_BASE_ADDR = 32'h4000_0000,
    parameter NUM_CTRL_REGS = 4,
    parameter NUM_USER_REGS = 16,
    localparam NUM_REGS = NUM_CTRL_REGS + NUM_USER_REGS
)();
    // Mailbox handle is passed at runtime via set_mailbox() because Verilator
    // does not support mailboxes in module port-lists.
    mailbox mon_mbx;

    // Setter to give the scoreboard the mailbox handle from the testbench
    task set_mailbox(mailbox mb);
        mon_mbx = mb;
    endtask

    bit verbose = 1;
    int err_count = 0;

    apb_ref_model #(
        .DATA_W    (DATA_WIDTH),
        .NUM_REGS  (NUM_REGS),
        .USE_FSM   (USE_APB_FSM)
    ) ref_model = new();

    function int get_error_count();
        return err_count;
    endfunction

    task reset_model();
        ref_model.reset();
    endtask

    task run();
        apb_transaction trans;
        int addr;
        bit exp_slverr;
        logic [DATA_WIDTH-1:0] exp_rdata;

        reset_model();
        err_count = 0;

        forever begin
            mon_mbx.get(trans);
            addr = ref_model.decode_address(trans.addr, SLAVE_BASE_ADDR);
            exp_slverr = ref_model.predict_slverr(addr, trans.is_write);

            if (trans.slverr !== exp_slverr) begin
                if (verbose)
                    $display("Scoreboard: SLVERR mismatch addr=%h idx=%0d exp=%b got=%b",
                             trans.addr, addr, exp_slverr, trans.slverr);
                err_count++;
            end

            if (!exp_slverr) begin
                if (trans.is_write && addr != -1 && addr != 1) begin
                    ref_model.apply_write(addr, trans.wdata);
                    if (verbose)
                        $display("Scoreboard: Write reg[%0d] <= %h", addr, trans.wdata);
                end
                else if (trans.is_read && trans.ready) begin
                    if (USE_APB_FSM && addr == 1) begin
                        if (verbose)
                            $display("Scoreboard: STATUS read (live): %h", trans.rdata);
                    end
                    else begin
                        exp_rdata = ref_model.predict_read(addr, trans.rdata);
                        if (trans.rdata !== exp_rdata) begin
                            $display("Scoreboard: Read mismatch addr=%h idx=%0d exp=%h got=%h",
                                     trans.addr, addr, exp_rdata, trans.rdata);
                            err_count++;
                        end
                        else if (verbose) begin
                            $display("Scoreboard: Read reg[%0d] OK: %h", addr, trans.rdata);
                        end
                    end
                end
            end
        end
    endtask
endmodule

`endif
