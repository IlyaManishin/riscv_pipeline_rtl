`include "risc-v.svh"

// =====================================================================
// Branch Unit Module
// =====================================================================
module br_unit
#(
    parameter int XLEN = 32
)
(
    input  logic [XLEN-1:0] rd1,
    input  logic [XLEN-1:0] rd2,
    input  logic            br_un,   // 0 = signed compare, 1 = unsigned compare
    input  logic [2:0]      funct3,

    output logic            br_taken
);

logic br_eq;
logic br_lt;

// ---------------------------------------------------------------------
// Comparator Instantiation
// ---------------------------------------------------------------------
br_comparator #(
    .XLEN (XLEN)
) br_comp_inst (
    .rd1   (rd1),
    .rd2   (rd2),
    .br_un (br_un),
    .br_eq (br_eq),
    .br_lt (br_lt)
);

// ---------------------------------------------------------------------
// Branch Evaluation Logic
// ---------------------------------------------------------------------
always_comb begin
    case (funct3)
        3'b000:  br_taken = br_eq;       // BEQ
        3'b001:  br_taken = ~br_eq;      // BNE
        3'b100:  br_taken = br_lt;       // BLT
        3'b101:  br_taken = ~br_lt;      // BGE
        3'b110:  br_taken = br_lt;       // BLTU
        3'b111:  br_taken = ~br_lt;      // BGEU
        default: br_taken = 1'b0;
    endcase
end

endmodule : br_unit