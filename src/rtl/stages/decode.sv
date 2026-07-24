`include "risc-v.svh"

module decode_stage import risc_v_pkg::*;
(
    input  logic               clk,
    input  logic               rst,

//---------HAZARD UNIT WIRES----------
    input  logic               stall_id,
    input  logic               flush_id,

    output logic               id_jfid,
    output Addr_t              id_imm_pc,
    output logic [OPCODE_WIDTH-1:0] id_opcode,
//------------------------------------

//-------REGISTER FILE ACCESS---------
    output RegAddr_t           rs1,
    output RegAddr_t           rs2,

    input  Data_t              rd1,
    input  Data_t              rd2,
//------------------------------------

//----------INPUT REGISTERS-----------
    input  Addr_t              pc_D,
    input  Instr_t             instr_D,
    input  logic               valid_D,
//------------------------------------

//----------INPUT REGISTERS-----------
    output Addr_t              pc_E,
    output Data_t              rd1_E,
    output Data_t              rd2_E,
    output Data_t              imm_E,
    output RegAddr_t           rs1_E,
    output RegAddr_t           rs2_E,
    output RegAddr_t           rd_E,
    output Id_controls_out_t   id_controls_E,
    output logic               valid_E
//------------------------------------

);

    // =========================================================================
    //  Internal Signals & Structs
    // =========================================================================

    RegAddr_t         rd;
    Data_t            imm;

    Id_instr_t        id_instr;
    Id_controls_in_t  id_controls_in;
    Id_controls_out_t id_output_controls;
    logic             id_illegal;

    Imm_input_t       ig_imm_input;


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

    assign id_imm_pc = pc_D + imm;
    assign id_jfid   = valid_D & (~id_output_controls.pc_sel);
    assign id_opcode = id_instr.opcode;


    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Istruction Decoder UNIT  ---
    id id_inst (
        .instr           ( id_instr           ),
        .input_controls  ( id_controls_in     ),
        .output_controls ( id_output_controls ),
        .illegal         ( id_illegal         )
    );

    // --- Immediate Generator ---
    imm_gen imm_gen_inst (
        .Imm_in   ( ig_imm_input             ),
        .imm_type ( id_output_controls.imm_type ),
        .imm      ( imm                      )
    );

    // --- Branch Unit ---
    branch_unit_m #(
        .XLEN ( XLEN )
    ) branch_unit_inst (
        .rd1   ( rd1                  ),
        .rd2   ( rd2                  ),
        .br_un ( id_output_controls.br_un ),
        .br_eq ( id_controls_in.br_eq ),
        .br_lt ( id_controls_in.br_lt )
    );

    // =========================================================================
    //  ID / EX Pipeline Registers
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst || flush_id) begin
            pc_E          <= '0;
            rd1_E         <= '0;
            rd2_E         <= '0;
            imm_E         <= '0;
            rs1_E         <= '0;
            rs2_E         <= '0;
            rd_E          <= '0;
            id_controls_E <= '0;
            valid_E       <= 1'b0;
        end else if (!stall_id) begin
            pc_E          <= pc_D;
            rd1_E         <= rd1;
            rd2_E         <= rd2;
            imm_E         <= imm;
            rs1_E         <= rs1;
            rs2_E         <= rs2;
            rd_E          <= rd;
            id_controls_E <= id_output_controls;
            valid_E       <= valid_D;
        end
    end

endmodule : decode_stage
