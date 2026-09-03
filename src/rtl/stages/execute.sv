`include "risc-v.svh"
`include "hazard_unit/hazard_unit_pkg.svh"

module execute_stage import risc_v_pkg::*, hazard_unit_pkg::*;
(
    input  logic               clk,
    input  logic               rst,

//---------HAZARD UNIT WIRES----------
    input  logic               stall_ex_mem,
    input  logic               flush_ex_mem,
//------------------------------------

//----------FORWARDING WIRES----------
    input  fwd_controls_t      fwd_controls,
//------------------------------------

//----------INPUT REGISTERS-----------
    input  addr_t              pc_E,
    input  data_t              rd1_E,
    input  data_t              rd2_E,
    input  data_t              imm_E,
    input  reg_addr_t          rs2_E,
    input  reg_addr_t          rd_E,
    input  logic [2:0]         funct3_E,
    input  id_controls_out_t   id_controls_E,
    input  logic               valid_E,
//------------------------------------

//---------HAZARD / JUMP OUT----------
    output logic               jfexe_M,
    output addr_t              jfpc_M,
//------------------------------------

//---------OUTPUT REGISTERS-----------
    output data_t              alu_out_M,
    output data_t              rd2_M,
    output reg_addr_t          rd_M,
    output addr_t              pc4_M,
    output id_controls_out_t   id_controls_M,
    output logic               valid_M
//------------------------------------
);

    // =========================================================================
    //  Internal Signals
    // =========================================================================
    data_t        bypassed_rd1_E;
    data_t        bypassed_rd2_E;

    data_t        alu_in_a;
    data_t        alu_in_b;
    data_t        alu_res;
    data_t        shifter_out;
    data_t        alu_out;
    shift_shamt_t shift_shamt;
    addr_t        pc4_E;

    logic         br_unit_res;
    logic         br_taken;
    logic         ex_jfexe;
    addr_t        ex_jfpc;

    // =========================================================================
    //  Forwarding Data Multiplexing
    // =========================================================================
    assign bypassed_rd1_E = fwd_controls.ex_fwd_sel1 ? fwd_controls.ex_fwd_wd1 : rd1_E;
    assign bypassed_rd2_E = fwd_controls.ex_fwd_sel2 ? fwd_controls.ex_fwd_wd2 : rd2_E;

    // =========================================================================
    //  ALU Operand Multiplexing & Control
    // =========================================================================
    assign alu_in_a    = id_controls_E.a_sel ? bypassed_rd1_E : pc_E;
    assign alu_in_b    = id_controls_E.b_sel ? bypassed_rd2_E : imm_E;
    assign shift_shamt = id_controls_E.b_sel ? bypassed_rd2_E[4:0] : rs2_E[4:0];

    assign pc4_E       = pc_E + 32'd4;
    assign alu_out     = id_controls_E.alushift_sel ? shifter_out : alu_res;

    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Arithmetic Logic Unit ---
    alu_m #(
        .XLEN ( XLEN )
    ) alu_inst (
        .sel ( id_controls_E.alu_sel ),
        .a   ( alu_in_a ),
        .b   ( alu_in_b ),
        .res ( alu_res )
    );

    // --- Shifter Unit ---
    risc_v_shifter_m #(
        .XLEN ( XLEN )
    ) shifter_inst (
        .data  ( bypassed_rd1_E ),
        .shamt ( shift_shamt ),
        .sel   ( id_controls_E.sh_sel ),
        .res   ( shifter_out )
    );

    // --- Branch Unit ---
    br_unit #(
        .XLEN ( XLEN )
    ) br_unit_inst (
        .rd1      ( bypassed_rd1_E      ),
        .rd2      ( bypassed_rd2_E      ),
        .br_un    ( id_controls_E.br_un ),
        .funct3   ( funct3_E            ),
        .br_taken ( br_unit_res         )
    );

    // =========================================================================
    //  Control-Hazard / Branch Resolution
    // =========================================================================
    assign br_taken = id_controls_E.br_unit_sel ? br_unit_res : 1'b1;
    assign ex_jfexe = valid_E & (!id_controls_E.pc_sel) & br_taken;    
    assign ex_jfpc  = alu_res;

    // =========================================================================
    //  EX / MEM Pipeline Registers
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst || flush_ex_mem) begin
            alu_out_M     <= '0;
            rd2_M         <= '0;
            rd_M          <= '0;
            pc4_M         <= '0;
            id_controls_M <= '0;
            valid_M       <= 1'b0;
            jfexe_M       <= 1'b0;
            jfpc_M        <= '0;
        end else if (!stall_ex_mem) begin
            alu_out_M     <= alu_out;
            rd2_M         <= bypassed_rd2_E;
            rd_M          <= rd_E;
            pc4_M         <= pc4_E;
            id_controls_M <= id_controls_E;
            valid_M       <= valid_E;
            jfexe_M       <= ex_jfexe;
            jfpc_M        <= ex_jfpc;
        end
    end

endmodule : execute_stage