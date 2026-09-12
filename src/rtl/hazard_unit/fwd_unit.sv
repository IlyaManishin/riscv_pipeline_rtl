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
    fwd_id_controls_t fwd_id;

    always_comb begin
        fwd_id.fwd_en1 = fwd_id_eq1;
        fwd_id.fwd_en2 = fwd_id_eq2;
        fwd_id.wd      = hu_wd.wd_W;
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
    fwd_ex_controls_t fwd_ex;

    always_comb begin
        fwd_ex.fwd_en1 = ex_sel1_reg.fwd_en;
        fwd_ex.fwd_en2 = ex_sel2_reg.fwd_en;

`ifdef USE_DMEM_WB_EX_FORWARDING
        // Full WB->EX forwarding (includes memory loads via wd_W)

        fwd_ex.wd1 = ex_sel1_reg.mem_wb_sel ? hu_wd.wd_M : hu_wd.wd_W;
        fwd_ex.wd2 = ex_sel2_reg.mem_wb_sel ? hu_wd.wd_M : hu_wd.wd_W;
`else
        // Partial WB->EX forwarding (only ALU result via alu_out_W)
        
        fwd_ex.wd1 = ex_sel1_reg.mem_wb_sel ? hu_wd.wd_M : hu_wd.alu_out_W;
        fwd_ex.wd2 = ex_sel2_reg.mem_wb_sel ? hu_wd.wd_M : hu_wd.alu_out_W;
`endif
    end

    // =====================================================================
    //  Total Struct Assembly
    // =====================================================================
    assign fwd_controls.id = fwd_id;
    assign fwd_controls.ex = fwd_ex;

endmodule : fwd_unit