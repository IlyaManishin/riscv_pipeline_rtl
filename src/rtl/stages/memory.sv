`include "risc-v.svh"

module memory_stage import risc_v_pkg::*;
(
    input  logic               clk,
    input  logic               rst,

//---------HAZARD UNIT WIRES--------------
    input  logic               stall_mem_wb,
    input  logic               flush_mem_wb,
//----------------------------------------

//----------INPUT REGISTERS---------------
    input  data_t              alu_out_M,
    input  data_t              rd2_M,
    input  reg_addr_t          rd_M,
    input  addr_t              pc4_M,
    input  id_controls_out_t   id_controls_M,
    input  logic               valid_M,
//----------------------------------------

//---------DMEM ACCESS--------------------
    output addr_t              dmem_addr,
    output byte_data_ena_t     dmem_byte_we,
    output data_t              dmem_wdata,
    input  data_t              cpu_rdata,
//----------------------------------------

//---------OUTPUT REGISTERS---------------
    output data_t              alu_out_W,
    output data_t              cpu_rdata_W,
    output reg_addr_t          rd_W,
    output addr_t              pc4_W,
    output id_controls_out_t   id_controls_W,
    output logic               valid_W
//----------------------------------------
);

    // =========================================================================
    //  Internal Signals & Logic
    // =========================================================================

    byte_addr_t dmem_byte_off;
    logic       dmem_we;

    assign dmem_addr     = alu_out_M;
    assign dmem_byte_off = alu_out_M[1:0];
    assign dmem_we       = id_controls_M.dmem_sel.dmem_we;


    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Data Memory Write Port ---
    risc_v_dmem_wr_port_m dmem_wr_port_inst (
        .dmem_we   ( dmem_we                   ),
        .funct3    ( id_controls_M.dmem_sel.funct3 ),
        .byte_addr ( dmem_byte_off             ),
        .data_in   ( rd2_M                     ),
        .we        ( dmem_byte_we              ),
        .data_out  ( dmem_wdata                )
    );


    // =========================================================================
    //  MEM / WB Pipeline Registers
    // =========================================================================

    assign cpu_rdata_W = cpu_rdata;

    always_ff @(posedge clk) begin
        if (rst || flush_mem_wb) begin
            alu_out_W     <= '0;
            rd_W          <= '0;
            pc4_W         <= '0;
            id_controls_W <= '0;
            valid_W       <= 1'b0;
        end else if (!stall_mem_wb) begin
            alu_out_W     <= alu_out_M;
            rd_W          <= rd_M;
            pc4_W         <= pc4_M;
            id_controls_W <= id_controls_M;
            valid_W       <= valid_M;
        end
    end

endmodule : memory_stage