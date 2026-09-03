`include "risc-v.svh"
`include "hazard_unit/hazard_unit_pkg.svh"

module fwd_unit import risc_v_pkg::*, hazard_unit_pkg::*;
(
    input  rsi_cmp_t       rsi_cmp,
    input  hu_regs_write_t hu_regs_write,
    input  hu_write_data_t hu_write_data,

    output fwd_controls_t  fwd_controls
);

    always_comb begin
        // =====================================================================
        //  ID Stage Forwarding (WB -> ID)
        // =====================================================================
        
        // Default values
        fwd_controls.id_fwd_sel1 = FWD_RF;
        fwd_controls.id_fwd_sel2 = FWD_RF;
        fwd_controls.id_fwd_wd   = hu_write_data.wd_W;

        // Forwarding to rs1
        if (hu_regs_write.reg_wr_W && rsi_cmp.rd_W_valid && rsi_cmp.eq1_W) begin
            fwd_controls.id_fwd_sel1 = FWD_STAGE;
        end

        // Forwarding to rs2
        if (hu_regs_write.reg_wr_W && rsi_cmp.rd_W_valid && rsi_cmp.eq2_W) begin
            fwd_controls.id_fwd_sel2 = FWD_STAGE;
        end

        // =====================================================================
        //  EX Stage Forwarding (Placeholder / Zeroed out)
        // =====================================================================
        
        fwd_controls.ex_fwd_sel1 = FWD_RF;
        fwd_controls.ex_fwd_sel2 = FWD_RF;
        fwd_controls.ex_fwd_wd1  = '0;
        fwd_controls.ex_fwd_wd2  = '0;
    end

endmodule : fwd_unit