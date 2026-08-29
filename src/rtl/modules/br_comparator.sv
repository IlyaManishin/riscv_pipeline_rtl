`include "risc-v.svh"

// =====================================================================
// Branch Comparator Module
// =====================================================================
module br_comparator
#(
    parameter int XLEN = 32
)
(
    input  logic [XLEN-1:0] rd1,
    input  logic [XLEN-1:0] rd2,
    input  logic            br_un,   // 0 = signed compare, 1 = unsigned compare

    output logic            br_eq,
    output logic            br_lt
);

// ---------------------------------------------------------------------
// Comparison Logic
// ---------------------------------------------------------------------
always_comb begin
    br_eq = (rd1 == rd2);

    if (br_un) begin
        br_lt = (rd1 < rd2);
    end else begin
        br_lt = ($signed(rd1) < $signed(rd2));
    end
end

endmodule : br_comparator_m