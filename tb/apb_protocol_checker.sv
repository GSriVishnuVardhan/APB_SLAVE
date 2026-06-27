// APB3 protocol checker (Verilator-friendly immediate checks)

`ifndef APB_PROTOCOL_CHECKER
`define APB_PROTOCOL_CHECKER
module apb_protocol_checker
#(
    parameter ADDRESS_WIDTH = 32
)
(
    apb_if #(ADDRESS_WIDTH, 32) vif
);
    int violation_count;

    function automatic int get_violation_count();
        return violation_count;
    endfunction

    always @(posedge vif.pclk) begin
        if (!vif.rst_n)
            ;
        else if (vif.penable && !vif.psel) begin
            violation_count = violation_count + 1;
            $display("PROTOCOL VIOLATION: PENABLE high without PSEL");
        end
        else if (vif.pready && !(vif.psel && vif.penable)) begin
            violation_count = violation_count + 1;
            $display("PROTOCOL VIOLATION: PREADY high outside ACCESS");
        end
    end
endmodule
`endif
