// SystemVerilog Assertions — use with Questa / Xcelium / VCS (not Verilator).

`ifndef APB_ASSERTIONS
`define APB_ASSERTIONS

module apb_assertions #(
    parameter ADDRESS_WIDTH = 32
)(
    apb_if #(ADDRESS_WIDTH, 32) vif,
    input logic offset_valid
);
    int failure_count;

    function automatic int get_failure_count();
        return failure_count;
    endfunction

    // PENABLE requires PSEL
    property p_enable_implies_psel;
        @(posedge vif.pclk) disable iff (!vif.rst_n)
            vif.penable |-> vif.psel;
    endproperty
    assert property (p_enable_implies_psel) else failure_count++;

    // PREADY only during ACCESS (PSEL && PENABLE)
    property p_ready_in_access;
        @(posedge vif.pclk) disable iff (!vif.rst_n)
            vif.pready |-> (vif.psel && vif.penable);
    endproperty
    assert property (p_ready_in_access) else failure_count++;

    // PADDR stable during SETUP and ACCESS while PSEL held
    property paddr_stable_while_selected;
        @(posedge vif.pclk) disable iff (!vif.rst_n)
            (vif.psel && !$past(vif.psel)) |=> (vif.paddr == $past(vif.paddr))
            throughout (##1 (vif.psel)[*1:$]);
    endproperty
    // Simplified: during ACCESS, address must match previous cycle if still selected
    property paddr_stable_in_access;
        @(posedge vif.pclk) disable iff (!vif.rst_n)
            (vif.psel && vif.penable) |-> (vif.paddr == $past(vif.paddr));
    endproperty
    assert property (paddr_stable_in_access) else failure_count++;

    // After completed beat (PREADY), master may deassert — no PREADY outside ACCESS
    property no_pready_after_deassert;
        @(posedge vif.pclk) disable iff (!vif.rst_n)
            $past(vif.pready && vif.psel && vif.penable) |-> !vif.pready;
    endproperty
    // Note: master may hold for back-to-back; checker is conservative

endmodule

`endif
