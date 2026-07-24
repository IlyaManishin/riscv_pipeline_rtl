`include "risc-v.svh"

/*
 * Module `id`
 *
 *   Decodes all RV32I instructions
 *
 *   Inputs:
 *     -           instr:  Id_instr_t           necessary instruction bits
 *     -  input_controls:  Id_controls_in_t     additional input signals
 *   Outputs:
 *     - output_controls:  Id_controls_out_t    output signals
 *     -         illegal:  logic                instruction is - 0: legal, 1: illegal
 */
module id import risc_v_pkg::*;
(
    input  Id_instr_t         instr,
    input  Id_controls_in_t   input_controls,
    output Id_controls_out_t  output_controls,
    output logic              illegal
);
    parameter int CASE_SIZE = $bits(Id_instr_t) + $bits(Id_controls_in_t);

    logic [2:0] funct3;
    assign funct3 = instr.funct3;

    `define set_default_signals                                                                                              \
        output_controls = { 1'b0, 4'b0000, 1'bx, 1'bx, SHIFT_ANY, 1'bx, 1'b1, ALU_ANY, WB_ANY, INSTR_TYPE_ANY, 1'b0, 1'b0 }; \
        illegal = 1'b1;

    logic [(CASE_SIZE - 1):0] case_key;

    always_comb begin
        case_key = {instr.funct7, funct3, instr.opcode, input_controls};
        illegal = 1'b0;

        if (instr.ones != 'b11) begin
            `set_default_signals;
        end else begin
            casex (case_key)
                // MNEMONIC  funct7_funct3_opcode_breq_brlt         reg_wr   dmem_sel         a_sel  b_sel  sh_sel      br_un  pc_sel  alu_sel    wb_sel           imm_type        jf_exe  alushift_sel
                /* LUI   */  'bx_xxx_01101_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'bx,  1'b1,   ALU_LUI,   WB_ALU_OUT,      INSTR_TYPE_U,   1'b0,   1'b0 };
                /* AUIPC */  'bx_xxx_00101_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_ALU_OUT,      INSTR_TYPE_U,   1'b0,   1'b0 };
                /* JAL   */  'bx_xxx_11011_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'bx,  1'b0,   ALU_ADD,   WB_PC4_OUT,      INSTR_TYPE_J,   1'b0,   1'b0 };
                /* JALR  */  'b0_000_11001_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b0,   ALU_JALR,  WB_PC4_OUT,      INSTR_TYPE_I,   1'b1,   1'b0 };

                // NOTE: in case when required `br_eq` or `br_lt` for branch command is wrong:
                //       we set flag `br_un` according to instruction, but also set `pc_sel=1` to move to the next instruction `PC+4` instead of branch
                /* BEQ   */  'bx_000_11000_1_x: output_controls = { 1'b0,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'b0,  1'b0,   ALU_ADD,   WB_ANY,          INSTR_TYPE_B,   1'b0,   1'b0 };
                /* BEQ   */  'bx_000_11000_0_x: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'b0,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* BNE   */  'bx_001_11000_0_x: output_controls = { 1'b0,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'b0,  1'b0,   ALU_ADD,   WB_ANY,          INSTR_TYPE_B,   1'b0,   1'b0 };
                /* BNE   */  'bx_001_11000_1_x: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'b0,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* BLT   */  'bx_100_11000_x_1: output_controls = { 1'b0,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'b0,  1'b0,   ALU_ADD,   WB_ANY,          INSTR_TYPE_B,   1'b0,   1'b0 };
                /* BLT   */  'bx_100_11000_x_0: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'b0,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* BGE   */  'bx_101_11000_x_0: output_controls = { 1'b0,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'b0,  1'b0,   ALU_ADD,   WB_ANY,          INSTR_TYPE_B,   1'b0,   1'b0 };
                /* BGE   */  'bx_101_11000_x_1: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'b0,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* BLTU  */  'bx_110_11000_x_1: output_controls = { 1'b0,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'b1,  1'b0,   ALU_ADD,   WB_ANY,          INSTR_TYPE_B,   1'b0,   1'b0 };
                /* BLTU  */  'bx_110_11000_x_0: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'b1,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* BGEU  */  'bx_111_11000_x_0: output_controls = { 1'b0,   {1'b0, 3'b000},  1'b0,  1'b0,  SHIFT_ANY,  1'b1,  1'b0,   ALU_ADD,   WB_ANY,          INSTR_TYPE_B,   1'b0,   1'b0 };
                /* BGEU  */  'bx_111_11000_x_1: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'b1,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };

                /* LB    */  'bx_000_00000_x_x: output_controls = { 1'b1,   {1'b0, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_DMEM_OUT,     INSTR_TYPE_I,   1'b0,   1'b0 };
                /* LH    */  'bx_001_00000_x_x: output_controls = { 1'b1,   {1'b0, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_DMEM_OUT,     INSTR_TYPE_I,   1'b0,   1'b0 };
                /* LW    */  'bx_010_00000_x_x: output_controls = { 1'b1,   {1'b0, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_DMEM_OUT,     INSTR_TYPE_I,   1'b0,   1'b0 };
                /* LBU   */  'bx_100_00000_x_x: output_controls = { 1'b1,   {1'b0, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_DMEM_OUT,     INSTR_TYPE_I,   1'b0,   1'b0 };
                /* LHU   */  'bx_101_00000_x_x: output_controls = { 1'b1,   {1'b0, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_DMEM_OUT,     INSTR_TYPE_I,   1'b0,   1'b0 };
                /* SB    */  'bx_000_01000_x_x: output_controls = { 1'b0,   {1'b1, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_ANY,          INSTR_TYPE_S,   1'b0,   1'b0 };
                /* SH    */  'bx_001_01000_x_x: output_controls = { 1'b0,   {1'b1, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_ANY,          INSTR_TYPE_S,   1'b0,   1'b0 };
                /* SW    */  'bx_010_01000_x_x: output_controls = { 1'b0,   {1'b1, funct3},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_ANY,          INSTR_TYPE_S,   1'b0,   1'b0 };
                /* ADDI  */  'bx_000_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_ALU_OUT,      INSTR_TYPE_I,   1'b0,   1'b0 };
                /* SLTI  */  'bx_010_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_SLT,   WB_ALU_OUT,      INSTR_TYPE_I,   1'b0,   1'b0 };
                /* SLTIU */  'bx_011_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_SLTU,  WB_ALU_OUT,      INSTR_TYPE_I,   1'b0,   1'b0 };
                /* XORI  */  'bx_100_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_XOR,   WB_ALU_OUT,      INSTR_TYPE_I,   1'b0,   1'b0 };
                /* ORI   */  'bx_110_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_OR,    WB_ALU_OUT,      INSTR_TYPE_I,   1'b0,   1'b0 };
                /* ANDI  */  'bx_111_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b0,  SHIFT_ANY,  1'bx,  1'b1,   ALU_AND,   WB_ALU_OUT,      INSTR_TYPE_I,   1'b0,   1'b0 };
                /* SLLI  */  'b0_001_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_SLL,  1'bx,  1'b1,   ALU_ANY,   WB_SHIFTER_OUT,  INSTR_TYPE_ANY, 1'b0,   1'b1 };
                /* SRLI  */  'b0_101_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_SRL,  1'bx,  1'b1,   ALU_ANY,   WB_SHIFTER_OUT,  INSTR_TYPE_ANY, 1'b0,   1'b1 };
                /* SRAI  */  'b1_101_00100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_SRA,  1'bx,  1'b1,   ALU_ANY,   WB_SHIFTER_OUT,  INSTR_TYPE_ANY, 1'b0,   1'b1 };
                /* ADD   */  'b0_000_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ADD,   WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* SUB   */  'b1_000_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_SUB,   WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* SLL   */  'b0_001_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_SLL,  1'bx,  1'b1,   ALU_ANY,   WB_SHIFTER_OUT,  INSTR_TYPE_ANY, 1'b0,   1'b1 };
                /* SLT   */  'b0_010_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_SLT,   WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* SLTU  */  'b0_011_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_SLTU,  WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* XOR   */  'b0_100_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_XOR,   WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* SRL   */  'b0_101_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_SRL,  1'bx,  1'b1,   ALU_ANY,   WB_SHIFTER_OUT,  INSTR_TYPE_ANY, 1'b0,   1'b1 };
                /* SRA   */  'b1_101_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_SRA,  1'bx,  1'b1,   ALU_ANY,   WB_SHIFTER_OUT,  INSTR_TYPE_ANY, 1'b0,   1'b1 };
                /* OR    */  'b0_110_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_OR,    WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* AND   */  'b0_111_01100_x_x: output_controls = { 1'b1,   {1'b0, 3'b000},  1'b1,  1'b1,  SHIFT_ANY,  1'bx,  1'b1,   ALU_AND,   WB_ALU_OUT,      INSTR_TYPE_ANY, 1'b0,   1'b0 };

                /* There goes unsupported instructions, we consider them as NOPs */
                /* FENCE
                   FENCE.TSO
                   PAUSE */  'bx_000_00011_x_x: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };
                /* ECALL
                   EBREAK */ 'b0_000_11100_x_x: output_controls = { 1'b0,   {1'b0, 3'b000},  1'bx,  1'bx,  SHIFT_ANY,  1'bx,  1'b1,   ALU_ANY,   WB_ANY,          INSTR_TYPE_ANY, 1'b0,   1'b0 };

                default: begin
                    `set_default_signals;
                end
            endcase
        end
    end

endmodule : id