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
    //  Forwarding Match Conditions & Hazard Flags
    // =====================================================================
    
    // Intermediate flags indicating if a stage has a valid register write
    logic fwd_mem_valid;
    logic fwd_wb_valid;
    logic fwd_id_valid;

    assign fwd_mem_valid = hu_regs_wr.reg_wr_E && rsi_cmp.rd_E_valid;
    assign fwd_wb_valid  = hu_regs_wr.reg_wr_M && rsi_cmp.rd_M_valid;
    assign fwd_id_valid  = hu_regs_wr.reg_wr_W && rsi_cmp.rd_W_valid;

    // Resolved forwarding match conditions for rs1 and rs2 per stage
    logic fwd_mem_eq1;
    logic fwd_mem_eq2;
    logic fwd_wb_eq1;
    logic fwd_wb_eq2;
    logic fwd_id_eq1;
    logic fwd_id_eq2;

    assign fwd_mem_eq1   = fwd_mem_valid && rsi_cmp.eq1_E;
    assign fwd_mem_eq2   = fwd_mem_valid && rsi_cmp.eq2_E;
    assign fwd_wb_eq1    = fwd_wb_valid  && rsi_cmp.eq1_M;
    assign fwd_wb_eq2    = fwd_wb_valid  && rsi_cmp.eq2_M;
    assign fwd_id_eq1    = fwd_id_valid  && rsi_cmp.eq1_W;
    assign fwd_id_eq2    = fwd_id_valid  && rsi_cmp.eq2_W;

    // =====================================================================
    //  ID Stage Forwarding (WB -> ID)
    // =====================================================================
    always_comb begin
        fwd_controls.id_fwd_sel1 = fwd_id_eq1;
        fwd_controls.id_fwd_sel2 = fwd_id_eq2;
        fwd_controls.id_fwd_wd   = hu_wd.wd_W;
    end

    // =====================================================================
    //  EX Stage Forwarding Precalculation (ID -> EX)
    // =====================================================================
    fwd_ex_sel_t next_ex_sel1;
    fwd_ex_sel_t next_ex_sel2;
    
    fwd_ex_sel_t ex_sel1_reg;
    fwd_ex_sel_t ex_sel2_reg;

    always_comb begin
        next_ex_sel1 = '0;
        next_ex_sel2 = '0;

        // --- Forwarding Selection for rs1 ---
        next_ex_sel1.fwd_en     = fwd_mem_eq1 || fwd_wb_eq1;
        next_ex_sel1.mem_wb_sel = fwd_mem_eq1;

        // --- Forwarding Selection for rs2 ---
        next_ex_sel2.fwd_en     = fwd_mem_eq2 || fwd_wb_eq2;
        next_ex_sel2.mem_wb_sel = fwd_mem_eq2;
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
        fwd_controls.ex_fwd_sel1 = ex_sel1_reg.fwd_en;
        fwd_controls.ex_fwd_wd1  = ex_sel1_reg.mem_wb_sel ? hu_wd.wd_M : hu_wd.wd_W;

        fwd_controls.ex_fwd_sel2 = ex_sel2_reg.fwd_en;
        fwd_controls.ex_fwd_wd2  = ex_sel2_reg.mem_wb_sel ? hu_wd.wd_M : hu_wd.wd_W;
    end

endmodule : fwd_unit