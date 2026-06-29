// APB3 protocol checker — Verilator-friendly procedural checks (always-on in regression).

`ifndef APB_PROTOCOL_CHECKER
`define APB_PROTOCOL_CHECKER

module apb_protocol_checker #(
    parameter ADDRESS_WIDTH = 32
)(
    apb_if vif
);
    int violation_count;

    function automatic int get_violation_count();
        return violation_count;
    endfunction

    always @(posedge vif.pclk) begin
        if (!vif.rst_n)
            ;
        else if (vif.penable && !vif.psel) begin
            violation_count++;
            $display("PROTOCOL VIOLATION [%0d]: PENABLE high without PSEL", violation_count);
        end
        else if (vif.pready && !(vif.psel && vif.penable)) begin
            violation_count++;
            $display("PROTOCOL VIOLATION [%0d]: PREADY high outside ACCESS phase", violation_count);
        end
    end
endmodule

`endif
