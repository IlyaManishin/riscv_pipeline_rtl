`include "risc-v.svh"

module hazard_detection_unit import risc_v_pkg::*;
(
    input  logic [RF_ADDR_WIDTH-1:0] id_rs1,
    input  logic [RF_ADDR_WIDTH-1:0] id_rs2,

    input  logic       jfexe_M,

    input  logic       ex_reg_wr,
    input  logic [RF_ADDR_WIDTH-1:0] ex_rd,

    input  logic       mem_reg_wr,
    input  logic [RF_ADDR_WIDTH-1:0] mem_rd,

    input  logic       wb_reg_wr,
    input  logic [RF_ADDR_WIDTH-1:0] wb_rd,

    output logic       stall_pc,
    output logic       stall_if_id,
    output logic       flush_id_ex,
    output logic       flush_ex_mem
);

    logic is_control_hazard;
    logic is_ex_hazard;
    logic is_mem_hazard;
    logic is_wb_hazard;

    assign is_ex_hazard  = ex_reg_wr  && (ex_rd  != '0) && ((ex_rd  == id_rs1) || (ex_rd  == id_rs2));
    assign is_mem_hazard = mem_reg_wr && (mem_rd != '0) && ((mem_rd == id_rs1) || (mem_rd == id_rs2));
    assign is_wb_hazard  = wb_reg_wr  && (wb_rd  != '0) && ((wb_rd  == id_rs1) || (wb_rd  == id_rs2));

    always_comb begin
        stall_pc     = 1'b0;
        stall_if_id  = 1'b0;
        flush_id_ex  = 1'b0;
        flush_ex_mem = 1'b0;

        // ===== Control Hazards =====
        if (jfexe_M) begin
            flush_id_ex  = 1'b1;
            flush_ex_mem = 1'b1;
        end

        // ===== Data Hazards (RAW) =====
        is_control_hazard = jfexe_M;

        if ((is_ex_hazard || is_mem_hazard || is_wb_hazard) ) begin
            if (!is_control_hazard) begin
                stall_pc = 1'b1;
            end
            
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
    end

endmodule
