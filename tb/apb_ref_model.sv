// Golden reference model — register array + decode rules (package for Verilator + simulators).

`ifndef APB_REF_MODEL_PKG
`define APB_REF_MODEL_PKG

package apb_ref_model_pkg;

    class apb_ref_model #(
        int unsigned DATA_W = 32,
        int unsigned NUM_REGS = 20,
        bit USE_FSM = 0
    );
        logic [DATA_W-1:0] regs [0:NUM_REGS-1];

        function void reset();
            foreach (regs[i]) regs[i] = '0;
        endfunction

        function automatic int decode_address(
            input logic [31:0] paddr,
            input logic [31:0] base_addr
        );
            logic offset_aligned;
            logic address_in_window;
            offset_aligned = (paddr[1:0] == 2'b00);
            address_in_window = (paddr >= base_addr)
                             && (paddr <= base_addr + NUM_REGS * 4 - 1);
            if (offset_aligned && address_in_window)
                return int'(paddr[7:0] >> 2);
            return -1;
        endfunction

        function automatic bit predict_slverr(input int addr, input bit is_write);
            if (addr < 0)
                return 1'b1;
            if (addr < NUM_REGS) begin
                if (is_write && addr == 1)
                    return 1'b1;
                return 1'b0;
            end
            return 1'b1;
        endfunction

        function void apply_write(input int addr, input logic [DATA_W-1:0] wdata);
            if (addr >= 0 && addr < NUM_REGS && addr != 1)
                regs[addr] = wdata;
        endfunction

        function automatic logic [DATA_W-1:0] predict_read(
            input int addr,
            input logic [DATA_W-1:0] status_live
        );
            if (USE_FSM && addr == 1)
                return status_live;
            if (addr >= 0 && addr < NUM_REGS)
                return regs[addr];
            return '0;
        endfunction
    endclass

endpackage

`endif
