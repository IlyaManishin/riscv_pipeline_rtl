`include "risc-v.svh"
`include "hazard_unit/hazard_unit_pkg.svh"

module fwd_unit import risc_v_pkg::*, hazard_unit_pkg::*;
(
    input  logic          clk,

    input  rsi_cmp_t      rsi_cmp,
    input  hu_regs_wr_t   hu_regs_wr,
    input  hu_wd_t        hu_wd,

    output fwd_controls_t fwd_controls
);

    // =====================================================================
    //  ID Stage Forwarding (WB -> ID)
    // =====================================================================
    always_comb begin
        fwd_controls.id_fwd_sel1 = 1'b0;
        fwd_controls.id_fwd_sel2 = 1'b0;
        fwd_controls.id_fwd_wd   = hu_wd.wd_W;

        // Forwarding to rs1
        if (hu_regs_wr.reg_wr_W && rsi_cmp.rd_W_valid && rsi_cmp.eq1_W) begin
            fwd_controls.id_fwd_sel1 = 1'b1;
        end

        // Forwarding to rs2
        if (hu_regs_wr.reg_wr_W && rsi_cmp.rd_W_valid && rsi_cmp.eq2_W) begin
            fwd_controls.id_fwd_sel2 = 1'b1;
        end
    end

    // =====================================================================
    //  EX Stage Forwarding Precalculation (ID -> EX)
    // =====================================================================
    fwd_ex_sel_t next_ex_sel1;
    fwd_ex_sel_t next_ex_sel2;
    
    fwd_ex_sel_t ex_sel1_reg;
    fwd_ex_sel_t ex_sel2_reg;

    always_comb begin
        if (hu_regs_wr.reg_wr_E && rsi_cmp.rd_E_valid && rsi_cmp.eq1_E)
            next_ex_sel1 = FWD_EX_MEM;
        else if (hu_regs_wr.reg_wr_M && rsi_cmp.rd_M_valid && rsi_cmp.eq1_M)
            next_ex_sel1 = FWD_EX_WB;
        else
            next_ex_sel1 = FWD_EX_RF;

        if (hu_regs_wr.reg_wr_E && rsi_cmp.rd_E_valid && rsi_cmp.eq2_E)
            next_ex_sel2 = FWD_EX_MEM;
        else if (hu_regs_wr.reg_wr_M && rsi_cmp.rd_M_valid && rsi_cmp.eq2_M)
            next_ex_sel2 = FWD_EX_WB;
        else
            next_ex_sel2 = FWD_EX_RF;
    end

    // Save precount in registers to load data in execute stage
    always_ff @(posedge clk) begin
        ex_sel1_reg <= next_ex_sel1;
        ex_sel2_reg <= next_ex_sel2;
    end

    // =====================================================================
    //  EX Stage Forwarding Output Muxing
    // =====================================================================
    always_comb begin
        fwd_controls.ex_fwd_sel1 = (ex_sel1_reg != FWD_EX_RF);
        fwd_controls.ex_fwd_wd1  = (ex_sel1_reg == FWD_EX_MEM) ? hu_wd.wd_M : hu_wd.wd_W;

        fwd_controls.ex_fwd_sel2 = (ex_sel2_reg != FWD_EX_RF);
        fwd_controls.ex_fwd_wd2  = (ex_sel2_reg == FWD_EX_MEM) ? hu_wd.wd_M : hu_wd.wd_W;
    end

endmodule : fwd_unit