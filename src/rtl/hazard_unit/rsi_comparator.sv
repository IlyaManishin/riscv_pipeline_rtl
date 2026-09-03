`include "risc-v.svh"

module rsi_comparator import hazard_unit_pkg::*;
(
    input  hu_reg_indexes_t rs_indexes,
    output rsi_cmp_t        rsi_cmp
);

    always_comb begin
        // Precalculate valid non-zero destination flags
        // don't check rs1/rs2 because there is imem net delay
        rsi_cmp.rd_E_valid = (rs_indexes.rd_E != '0);
        rsi_cmp.rd_M_valid = (rs_indexes.rd_M != '0);
        rsi_cmp.rd_W_valid = (rs_indexes.rd_W != '0);

        // Match conditions for rs1
        rsi_cmp.eq1_E = (rs_indexes.rs1 == rs_indexes.rd_E);
        rsi_cmp.eq1_M = (rs_indexes.rs1 == rs_indexes.rd_M);
        rsi_cmp.eq1_W = (rs_indexes.rs1 == rs_indexes.rd_W);

        // Match conditions for rs2
        rsi_cmp.eq2_E = (rs_indexes.rs2 == rs_indexes.rd_E);
        rsi_cmp.eq2_M = (rs_indexes.rs2 == rs_indexes.rd_M);
        rsi_cmp.eq2_W = (rs_indexes.rs2 == rs_indexes.rd_W);
    end

endmodule : rsi_comparator