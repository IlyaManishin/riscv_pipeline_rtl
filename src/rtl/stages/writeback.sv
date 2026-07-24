`include "risc-v.svh"

module writeback_stage import risc_v_pkg::*;
(
    input  Data_t            alu_out_W,
    input  Data_t            dmem_data_W,
    input  RegAddr_t         rd_W,
    input  Addr_t            pc4_W,
    input  Id_controls_out_t id_controls_W,
    input  logic             valid_W,

    output RegAddr_t         wb_rd,
    output Data_t            wb_wd3,
    output logic             wb_we3
);

    assign wb_rd  = rd_W;
    assign wb_we3 = id_controls_W.reg_wr;

    always_comb begin
        case (id_controls_W.wb_sel)
            WB_PC4_OUT     : wb_wd3 = pc4_W;
            WB_ALU_OUT     : wb_wd3 = alu_out_W;
            WB_SHIFTER_OUT : wb_wd3 = alu_out_W;
            WB_DMEM_OUT    : wb_wd3 = dmem_data_W;
            default        : wb_wd3 = '0;
        endcase
    end

endmodule : writeback_stage
