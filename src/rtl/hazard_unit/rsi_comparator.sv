`include "risc-v.svh"

module rsi_comparator import hazard_unit_pkg::*;
(
    input  rs_indexes_t rs_indexes,
    output rsi_cmp_t    rsi_cmp
);

    logic rs1_valid;
    logic rs2_valid;

    always_comb begin
        // Precalculate valid non-zero register source flags
        rs1_valid = (rs_indexes.rs1 != '0);
        rs2_valid = (rs_indexes.rs2 != '0);

        // Match conditions for rs1 (EX, MEM, WB)
        rsi_cmp.eq1_E = rs1_valid && (rs_indexes.rs1 == rs_indexes.rd_E);
        rsi_cmp.eq1_M = rs1_valid && (rs_indexes.rs1 == rs_indexes.rd_M);
        rsi_cmp.eq1_W = rs1_valid && (rs_indexes.rs1 == rs_indexes.rd_W);

        // Match conditions for rs2 (EX, MEM, WB)
        rsi_cmp.eq2_E = rs2_valid && (rs_indexes.rs2 == rs_indexes.rd_E);
        rsi_cmp.eq2_M = rs2_valid && (rs_indexes.rs2 == rs_indexes.rd_M);
        rsi_cmp.eq2_W = rs2_valid && (rs_indexes.rs2 == rs_indexes.rd_W);
    end

endmodule : rsi_comparator