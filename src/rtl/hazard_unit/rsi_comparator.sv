`include "risc-v.svh"

module rsi_comparator import hazard_unit_pkg::*;
(
    input  hu_reg_idxs_t rs_idxs,
    output rsi_cmp_t     rsi_cmp
);

    always_comb begin
        // Precalculate valid non-zero destination flags
        // Don't check rs1/rs2 because there is imem net delay
        rsi_cmp.rd_E_valid = (rs_idxs.rd_E != '0);
        rsi_cmp.rd_M_valid = (rs_idxs.rd_M != '0);
        rsi_cmp.rd_W_valid = (rs_idxs.rd_W != '0);

        // Match conditions for rs1
        rsi_cmp.eq1_E = (rs_idxs.rs1 == rs_idxs.rd_E);
        rsi_cmp.eq1_M = (rs_idxs.rs1 == rs_idxs.rd_M);
        rsi_cmp.eq1_W = (rs_idxs.rs1 == rs_idxs.rd_W);

        // Match conditions for rs2
        rsi_cmp.eq2_E = (rs_idxs.rs2 == rs_idxs.rd_E);
        rsi_cmp.eq2_M = (rs_idxs.rs2 == rs_idxs.rd_M);
        rsi_cmp.eq2_W = (rs_idxs.rs2 == rs_idxs.rd_W);
    end

endmodule : rsi_comparator