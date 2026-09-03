`include "risc-v.svh"
`include "hazard_unit/hazard_unit_pkg.svh"

module decode_stage import risc_v_pkg::*, hazard_unit_pkg::*;
(
    input  logic               clk,
    input  logic               rst,

//---------HAZARD UNIT WIRES------------
    input  logic               stall_id_ex,
    input  logic               flush_id_ex,
//--------------------------------------

//--------REGISTER FILE ACCESS----------
    output reg_addr_t          rs1,
    output reg_addr_t          rs2,

    input  data_t              rd1,
    input  data_t              rd2,
//--------------------------------------

//---------FORWARDING WIRES-------------
    input  logic               id_fwd_sel1,
    input  logic               id_fwd_sel2,
    input  data_t              id_fwd_wd,
//--------------------------------------

//---------INPUT REGISTERS--------------
    input  addr_t              pc_D,
    input  instr_t             instr_D,
    input  logic               valid_D,
//--------------------------------------

//---------OUTPUT REGISTERS-------------
    output addr_t              pc_E,
    output data_t              rd1_E,
    output data_t              rd2_E,
    output data_t              imm_E,
    output reg_addr_t          rs2_E,
    output reg_addr_t          rd_E,
    output logic [2:0]         funct3_E,
    output id_controls_out_t   id_controls_E,
    output logic               valid_E
//--------------------------------------
);

    // =========================================================================
    //  Internal Signals & Structs
    // =========================================================================

    reg_addr_t        rd;
    data_t            imm;

    id_instr_t        id_instr;
    id_controls_out_t id_output_controls;
    logic             id_illegal;

    imm_input_t       ig_imm_input;

    data_t            bypassed_rd1;
    data_t            bypassed_rd2;


    // =========================================================================
    //  Instruction Decoding & Field Extraction
    // =========================================================================
    assign rs1 = instr_D[19:15];
    assign rs2 = instr_D[24:20];
    assign rd  = instr_D[11:7];

    assign ig_imm_input = instr_D[31:7];

    assign id_instr.funct7 = instr_D[30];
    assign id_instr.funct3 = instr_D[14:12];
    assign id_instr.opcode = instr_D[6:2];
    assign id_instr.ones   = instr_D[1:0];

    // =========================================================================
    //  Forwarding Multiplexers (WB -> ID Bypass)
    // =========================================================================
    assign bypassed_rd1 = id_fwd_sel1 ? id_fwd_wd : rd1;
    assign bypassed_rd2 = id_fwd_sel2 ? id_fwd_wd : rd2;

    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Instruction Decoder UNIT ---
    id id_inst (
        .instr           ( id_instr           ),
        .output_controls ( id_output_controls ),
        .illegal         ( id_illegal         )
    );

    // --- Immediate Generator ---
    imm_gen imm_gen_inst (
        .Imm_in     ( ig_imm_input                  ),
        .instr_type ( id_output_controls.instr_type ),
        .imm        ( imm                           )
    );

    // =========================================================================
    //  ID / EX Pipeline Registers
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst || flush_id_ex || !valid_D) begin
            pc_E          <= '0;
            rd1_E         <= '0;
            rd2_E         <= '0;
            imm_E         <= '0;
            rs2_E         <= '0;
            rd_E          <= '0;
            funct3_E      <= '0;
            id_controls_E <= '0;
            valid_E       <= 1'b0;
        end else if (!stall_id_ex) begin
            pc_E          <= pc_D;
            rd1_E         <= bypassed_rd1;
            rd2_E         <= bypassed_rd2;
            imm_E         <= imm;
            rs2_E         <= rs2;
            rd_E          <= rd;
            funct3_E      <= id_instr.funct3;
            id_controls_E <= id_output_controls;
            valid_E       <= valid_D;
        end
    end

endmodule : decode_stage