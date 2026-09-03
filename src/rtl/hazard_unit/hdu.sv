`include "risc-v.svh"

module hazard_detection_unit import hazard_unit_pkg::*;
(
    input  rsi_cmp_t        rsi_cmp,
    input  hu_regs_write_t  hu_regs_write,
    input  logic            jfexe_M,

    output hdu_controls_t   hdu_controls
);

    logic is_control_hazard;
    logic is_ex_hazard;
    logic is_mem_hazard;
    logic is_wb_hazard;
    logic ex_reg_wr;
    logic mem_reg_wr;
    logic wb_reg_wr;
    
    assign ex_reg_wr  = hu_regs_write.reg_wr_E;
    assign mem_reg_wr = hu_regs_write.reg_wr_M;
    assign wb_reg_wr  = hu_regs_write.reg_wr_W;

    assign is_ex_hazard  = ex_reg_wr  && rsi_cmp.rd_E_valid && (rsi_cmp.eq1_E || rsi_cmp.eq2_E);
    assign is_mem_hazard = mem_reg_wr && rsi_cmp.rd_M_valid && (rsi_cmp.eq1_M || rsi_cmp.eq2_M);
    // assign is_wb_hazard  = wb_reg_wr  && rsi_cmp.rd_W_valid && (rsi_cmp.eq1_W || rsi_cmp.eq2_W);

    always_comb begin
        hdu_controls = '0;

        // ===== Control Hazards =====
        if (jfexe_M) begin
            hdu_controls.flush_id_ex  = 1'b1;
            hdu_controls.flush_ex_mem = 1'b1;
        end

        // ===== Data Hazards (RAW) =====
        is_control_hazard = jfexe_M;

        if (is_ex_hazard || is_mem_hazard) begin
            if (!is_control_hazard) begin
                hdu_controls.stall_pc = 1'b1;
                hdu_controls.stall_if_id = 1'b1;
            end
            
            hdu_controls.flush_id_ex = 1'b1;
        end
    end

endmodule : hazard_detection_unit