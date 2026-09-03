`include "risc-v.svh"
`include "hazard_unit/hazard_unit_pkg.svh"

module fwd_unit import risc_v_pkg::*, hazard_unit_pkg::*;
(
    input  logic           clk,

    input  rsi_cmp_t       rsi_cmp,
    input  hu_regs_write_t hu_regs_write,
    input  hu_write_data_t hu_write_data,

    output fwd_controls_t  fwd_controls
);

    // =====================================================================
    //  ID Stage Forwarding (WB -> ID)
    // =====================================================================
    always_comb begin
        fwd_controls.id_fwd_sel1 = 1'b0;
        fwd_controls.id_fwd_sel2 = 1'b0;
        fwd_controls.id_fwd_wd   = hu_write_data.wd_W;

        // Forwarding to rs1
        if (hu_regs_write.reg_wr_W && rsi_cmp.rd_W_valid && rsi_cmp.eq1_W) begin
            fwd_controls.id_fwd_sel1 = 1'b1;
        end

        // Forwarding to rs2
        if (hu_regs_write.reg_wr_W && rsi_cmp.rd_W_valid && rsi_cmp.eq2_W) begin
            fwd_controls.id_fwd_sel2 = 1'b1;
        end
    end

    // =====================================================================
    //  EX Stage Forwarding Precalculation (ID -> EX)
    // =====================================================================
    fwd_ex_sel_t nxt_sel1;
    fwd_ex_sel_t nxt_sel2;
    
    fwd_ex_sel_t ex_sel1_q;
    fwd_ex_sel_t ex_sel2_q;

    always_comb begin
        if (hu_regs_write.reg_wr_E && rsi_cmp.rd_E_valid && rsi_cmp.eq1_E)
            nxt_sel1 = FWD_EX_MEM;
        else if (hu_regs_write.reg_wr_M && rsi_cmp.rd_M_valid && rsi_cmp.eq1_M)
            nxt_sel1 = FWD_EX_WB;
        else
            nxt_sel1 = FWD_EX_RF;

        if (hu_regs_write.reg_wr_E && rsi_cmp.rd_E_valid && rsi_cmp.eq2_E)
            nxt_sel2 = FWD_EX_MEM;
        else if (hu_regs_write.reg_wr_M && rsi_cmp.rd_M_valid && rsi_cmp.eq2_M)
            nxt_sel2 = FWD_EX_WB;
        else
            nxt_sel2 = FWD_EX_RF;
    end

    // Direct FF for critical path optimization (no stall/flush logic needed)
    always_ff @(posedge clk) begin
        ex_sel1_q <= nxt_sel1;
        ex_sel2_q <= nxt_sel2;
    end

    // =====================================================================
    //  EX Stage Forwarding Output Muxing
    // =====================================================================
    always_comb begin
        fwd_controls.ex_fwd_sel1 = (ex_sel1_q != FWD_EX_RF);
        fwd_controls.ex_fwd_wd1  = (ex_sel1_q == FWD_EX_MEM) ? hu_write_data.wd_M : hu_write_data.wd_W;

        fwd_controls.ex_fwd_sel2 = (ex_sel2_q != FWD_EX_RF);
        fwd_controls.ex_fwd_wd2  = (ex_sel2_q == FWD_EX_MEM) ? hu_write_data.wd_M : hu_write_data.wd_W;
    end

endmodule : fwd_unit