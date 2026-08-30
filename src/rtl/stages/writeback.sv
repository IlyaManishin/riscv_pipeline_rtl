`include "risc-v.svh"

module writeback_stage import risc_v_pkg::*;
(
//----------INPUT REGISTERS------------
    input  data_t            alu_out_W,
    input  data_t            cpu_rdata_W,
    input  reg_addr_t        rd_W,
    input  addr_t            pc4_W,
    input  id_controls_out_t id_controls_W,
    input  logic             valid_W,
//-------------------------------------

//---------REGISTER FILE WRITE---------
    output reg_addr_t        wb_rd,
    output data_t            wb_wd3,
    output logic             wb_we3
//-------------------------------------
);

    // =========================================================================
    //  Internal Signals & Logic
    // =========================================================================

    data_t cpu_port_rdata;
    assign dmem_byte_off = alu_out_W[1:0];

    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Data Memory Read Port ---
    risc_v_dmem_rd_port_m dmem_rd_port_inst (
        .funct3    ( id_controls_W.dmem_sel.funct3 ),
        .byte_addr ( alu_out_W[1:0]                ),
        .data_in   ( cpu_rdata_W                   ),
        .data_out  ( cpu_port_rdata                )
    );


    // =========================================================================
    //  Writeback Control & Multiplexing
    // =========================================================================

    assign wb_rd  = rd_W;
    assign wb_we3 = id_controls_W.reg_wr;

    always_comb begin
        case (id_controls_W.wb_sel)
            WB_PC4_OUT : wb_wd3 = pc4_W;
            WB_ALU_OUT : wb_wd3 = alu_out_W;
            WB_DMEM_OUT: wb_wd3 = cpu_port_rdata;
            default    : wb_wd3 = '0;
        endcase
    end

endmodule : writeback_stage