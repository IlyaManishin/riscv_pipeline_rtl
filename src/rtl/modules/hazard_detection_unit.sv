`include "risc-v.svh"

module hazard_detection_unit import risc_v_pkg::*;
(
    input  logic [RF_ADDR_WIDTH-1:0] id_rs1,
    input  logic [RF_ADDR_WIDTH-1:0] id_rs2,
    input  logic [OPCODE_WIDTH-1:0] id_opcode,
    input  logic       id_jf_exe,
    input  logic       id_jfid,

    input  logic       ex_reg_wr,
    input  logic [RF_ADDR_WIDTH-1:0] ex_rd,
    input  logic       ex_jfexe,

    input  logic       mem_reg_wr,
    input  logic [RF_ADDR_WIDTH-1:0] mem_rd,

    input  logic       wb_reg_wr,
    input  logic [RF_ADDR_WIDTH-1:0] wb_rd,

    output logic       stall_pc,
    output logic       stall_if_id,
    output logic       flush_if_id,
    output logic       flush_id_ex
);

    logic uses_rs1;
    logic uses_rs2;
    logic is_ex_hazard;
    logic is_mem_hazard;
    logic is_wb_hazard;

    always_comb begin
        case (id_opcode)
            5'b11001: begin uses_rs1 = 1'b1; uses_rs2 = 1'b0; end
            5'b11000: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end
            5'b00000: begin uses_rs1 = 1'b1; uses_rs2 = 1'b0; end
            5'b01000: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end
            5'b00100: begin uses_rs1 = 1'b1; uses_rs2 = 1'b0; end
            5'b01100: begin uses_rs1 = 1'b1; uses_rs2 = 1'b1; end
            default:  begin uses_rs1 = 1'b0; uses_rs2 = 1'b0; end
        endcase
    end

    assign is_ex_hazard  = ex_reg_wr  && (ex_rd != '0)  && ((uses_rs1 && (ex_rd == id_rs1))  || (uses_rs2 && (ex_rd == id_rs2)));
    assign is_mem_hazard = mem_reg_wr && (mem_rd != '0) && ((uses_rs1 && (mem_rd == id_rs1)) || (uses_rs2 && (mem_rd == id_rs2)));
    assign is_wb_hazard  = wb_reg_wr  && (wb_rd != '0)  && ((uses_rs1 && (wb_rd == id_rs1))  || (uses_rs2 && (wb_rd == id_rs2)));

    always_comb begin
        stall_pc    = 1'b0;
        stall_if_id = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;

        if (id_jf_exe) begin
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
            flush_if_id = 1'b1;
        end

        if (ex_jfexe) begin
            flush_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end

        if (id_jfid) begin
            flush_if_id = 1'b1;
        end

        if (is_ex_hazard || is_mem_hazard || is_wb_hazard) begin
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
    end

endmodule