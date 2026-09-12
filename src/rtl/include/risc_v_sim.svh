//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//  description:   Simulation-specific definitions and debug functions
//------------------------------------------------------------------------------

`ifndef RISC_V_SIM_SVH
`define RISC_V_SIM_SVH

`include "risc_v.svh"

// synopsys translate_off
`ifndef SIMULATOR
    `define SIMULATOR
`endif
// synopsys translate_on

package risc_v_sim_pkg;

    import risc_v_pkg::*;

    localparam int NN = 30;
    typedef logic [0:NN*8-1] str_t;

    //---
    function automatic str_t string2str(input string in, input int N = NN);
        str_t out = '0;
        for(int i = 0; i < N && i < in.len(); i++) begin
            out[(i*8)+:8] = in[i];
        end
        return out;    
    endfunction : string2str

    //---
    function automatic str_t disasm(input instr_t instr);
        logic[8:0] case_key = { instr[30], instr[14:12], instr[6:2] };

        //--- imm generation
        int imm_i_type = signed'({{20{instr[31]}}, instr[31:20]});
        int imm_s_type = signed'({{20{instr[31]}}, instr[31:25], instr[11:7]});
        int imm_b_type = signed'({{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:9], 2'b00});
        int imm_u_type = signed'({instr[31:12], 12'b0});
        int imm_j_type = signed'({{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:22], 2'b00});

        logic [4:0] shamt = instr[24:20];

        string format_str;

        casex (case_key)
            /* LUI   */  'bx_xxx_01101: format_str = $sformatf("lui x%0d, %0d", instr[11:7], imm_u_type);
            /* AUIPC */  'bx_xxx_00101: format_str = $sformatf("auipc x%0d, %0d", instr[11:7], imm_u_type);
            /* JAL   */  'bx_xxx_11011: format_str = $sformatf("jal x%0d, %0d", instr[11:7], imm_j_type);
            /* JALR  */  'b0_000_11001: format_str = $sformatf("jalr x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* BEQ   */  'bx_000_11000: format_str = $sformatf("beq x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
            /* BNE   */  'bx_001_11000: format_str = $sformatf("bne x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
            /* BLT   */  'bx_100_11000: format_str = $sformatf("blt x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
            /* BGE   */  'bx_101_11000: format_str = $sformatf("bge x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
            /* BLTU  */  'bx_110_11000: format_str = $sformatf("bltu x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
            /* BGEU  */  'bx_111_11000: format_str = $sformatf("bgeu x%0d, x%0d, %0d", instr[19:15], instr[24:20], imm_b_type);
            /* LB    */  'bx_000_00000: format_str = $sformatf("lb x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
            /* LH    */  'bx_001_00000: format_str = $sformatf("lh x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
            /* LW    */  'bx_010_00000: format_str = $sformatf("lw x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
            /* LBU   */  'bx_100_00000: format_str = $sformatf("lbu x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
            /* LHU   */  'bx_101_00000: format_str = $sformatf("lhu x%0d, %0d(x%0d)", instr[11:7], imm_i_type, instr[19:15]);
            /* SB    */  'bx_000_01000: format_str = $sformatf("sb x%0d, %0d(x%0d)", instr[24:20], imm_s_type, instr[19:15]);
            /* SH    */  'bx_001_01000: format_str = $sformatf("sh x%0d, %0d(x%0d)", instr[24:20], imm_s_type, instr[19:15]);
            /* SW    */  'bx_010_01000: format_str = $sformatf("sw x%0d, %0d(x%0d)", instr[24:20], imm_s_type, instr[19:15]);
            /* ADDI  */  'bx_000_00100: format_str = $sformatf("addi x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* SLTI  */  'bx_010_00100: format_str = $sformatf("slti x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* SLTIU */  'bx_011_00100: format_str = $sformatf("sltiu x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* XORI  */  'bx_100_00100: format_str = $sformatf("xori x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* ORI   */  'bx_110_00100: format_str = $sformatf("ori x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* ANDI  */  'bx_111_00100: format_str = $sformatf("andi x%0d, x%0d, %0d", instr[11:7], instr[19:15], imm_i_type);
            /* SLLI  */  'b0_001_00100: format_str = $sformatf("slli x%0d, x%0d, %0d", instr[11:7], instr[19:15], shamt);
            /* SRLI  */  'b0_101_00100: format_str = $sformatf("srli x%0d, x%0d, %0d", instr[11:7], instr[19:15], shamt);
            /* SRAI  */  'b1_101_00100: format_str = $sformatf("srai x%0d, x%0d, %0d", instr[11:7], instr[19:15], shamt);
            /* ADD   */  'b0_000_01100: format_str = $sformatf("add x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* SUB   */  'b1_000_01100: format_str = $sformatf("sub x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* SLL   */  'b0_001_01100: format_str = $sformatf("sll x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* SLT   */  'b0_010_01100: format_str = $sformatf("slt x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* SLTU  */  'b0_011_01100: format_str = $sformatf("sltu x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* XOR   */  'b0_100_01100: format_str = $sformatf("xor x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* SRL   */  'b0_101_01100: format_str = $sformatf("srl x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* SRA   */  'b1_101_01100: format_str = $sformatf("sra x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* OR    */  'b0_110_01100: format_str = $sformatf("or x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);
            /* AND   */  'b0_111_01100: format_str = $sformatf("and x%0d, x%0d, x%0d", instr[11:7], instr[19:15], instr[24:20]);

            /* NOPs */
            'bx_000_00011: format_str = $sformatf("nop");
            'b0_000_11100: format_str = $sformatf("nop");

            default: begin
                format_str = $sformatf("n/i");
            end
        endcase

        return string2str(format_str);
    endfunction : disasm

endpackage : risc_v_sim_pkg

`endif // RISC_V_SIM_SVH