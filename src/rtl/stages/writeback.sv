`include "risc-v.svh"

module writeback_stage import risc_v_pkg::*;
(
//----------INPUT REGISTERS------------
    input  Data_t            alu_out_W,
    input  Data_t            cpu_rdata_W,
    input  RegAddr_t         rd_W,
    input  Addr_t            pc4_W,
    input  Id_controls_out_t id_controls_W,
    input  logic             valid_W,

    // rd_port byte-select, precomputed in MEM
    input  RdByteSel_t       rd_byte_sel_W,
//-------------------------------------

//---------REGISTER FILE WRITE---------
    output RegAddr_t         wb_rd,
    output Data_t            wb_wd3,
    output logic             wb_we3
//-------------------------------------
);

    // =========================================================================
    //  Internal Signals & Logic
    // =========================================================================

    Data_t cpu_port_rdata;

    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Data Memory Read Port ---
    // byte_addr not needed here anymore - byte-select already computed in MEM
    dmem_rd_port_m dmem_rd_port_inst (
        .funct3      ( id_controls_W.dmem_sel.funct3),
        .rd_byte_sel ( rd_byte_sel_W                ),
        .data_in     ( cpu_rdata_W                  ),
        .data_out    ( cpu_port_rdata               )
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