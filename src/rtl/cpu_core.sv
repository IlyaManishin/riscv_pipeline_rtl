`include "risc-v.svh"

module cpu_core_m import risc_v_pkg::*;
(
    input  logic         clk,
    input  logic         rst,

    // =========================================================================
    //  Instruction Memory Interface
    // =========================================================================
    output Addr_t        imem_addr,
    input  Instr_t       instr,

    // =========================================================================
    //  Data Memory Interface
    // =========================================================================
    output Addr_t        dmem_addr,
    output ByteDataEna_t dmem_byte_we,
    output Data_t        dmem_data_in,
    input  Data_t        dmem_data_out
);

    // =========================================================================
    //  Hazard Detection Unit Signals & Instance
    // =========================================================================
    logic stall_pc;
    logic stall_if_id;
    logic flush_if_id;
    logic flush_id_ex;

    logic ex_reg_wr;
    logic mem_reg_wr;

    assign ex_reg_wr  = id_controls_E.reg_wr;
    assign mem_reg_wr = id_controls_M.reg_wr;

    hazard_detection_unit hazard_unit_inst (
        .id_rs1      ( rs1                  ),
        .id_rs2      ( rs2                  ),
        .id_opcode   ( id_opcode            ),
        .id_jf_exe   ( id_controls_E.jf_exe ),
        .id_jfid     ( id_jfid              ),
        .ex_reg_wr   ( ex_reg_wr            ),
        .ex_rd       ( rd_E                 ),
        .ex_jfexe    ( ex_jfexe             ),
        .mem_reg_wr  ( mem_reg_wr           ),
        .mem_rd      ( rd_M                 ),
        .wb_reg_wr   ( wb_rf_we3            ),
        .wb_rd       ( wb_rd                ),
        .stall_pc    ( stall_pc             ),
        .stall_if_id ( stall_if_id          ),
        .flush_if_id ( flush_if_id          ),
        .flush_id_ex ( flush_id_ex          )
    );

    // =========================================================================
    //  Register File Signals & Instance
    // =========================================================================
    RegAddr_t rs1;
    RegAddr_t rs2;
    Data_t    rf_rd1;
    Data_t    rf_rd2;

    RegAddr_t wb_rd;
    Data_t    wb_wd3;
    logic     wb_rf_we3;

    register_file #(
        .XLEN ( XLEN )
    ) rf_inst (
        .clk  ( clk       ),
        .rsi1 ( rs1       ),
        .rs1  ( rf_rd1    ),
        .rsi2 ( rs2       ),
        .rs2  ( rf_rd2    ),
        .rdi  ( wb_rd     ),
        .rd   ( wb_wd3    ),
        .we   ( wb_rf_we3 )
    );

    // =========================================================================
    //  Fetch Stage (IF) Signals & Instance
    // =========================================================================
    Addr_t  pc_D;
    Instr_t instr_D;
    logic   valid_D;

    fetch_stage fetch_stage_inst (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .stall_if  ( stall_pc    ),
        .flush_if  ( flush_if_id ),
        .id_jfid   ( id_jfid     ),
        .id_imm_pc ( id_imm_pc   ),
        .ex_jfexe  ( ex_jfexe    ),
        .ex_alures ( ex_alures   ),
        .imem_addr ( imem_addr   ),
        .instr     ( instr       ),
        .pc_D      ( pc_D        ),
        .instr_D   ( instr_D     ),
        .valid_D   ( valid_D     )
    );

    // =========================================================================
    //  Decode Stage (ID) Signals & Instance
    // =========================================================================
    logic                    id_jfid;
    Addr_t                   id_imm_pc;
    logic [OPCODE_WIDTH-1:0] id_opcode;

    Addr_t                   pc_E;
    Data_t                   rd1_E;
    Data_t                   rd2_E;
    Data_t                   imm_E;
    RegAddr_t                rs1_E;
    RegAddr_t                rs2_E;
    RegAddr_t                rd_E;
    Id_controls_out_t        id_controls_E;
    logic                    valid_E;

    decode_stage decode_stage_inst (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .stall_id      ( stall_if_id   ),
        .flush_id      ( flush_id_ex   ),
        .id_jfid       ( id_jfid       ),
        .id_imm_pc     ( id_imm_pc     ),
        .id_opcode     ( id_opcode     ),
        .rs1           ( rs1           ),
        .rs2           ( rs2           ),
        .rd1           ( rf_rd1        ),
        .rd2           ( rf_rd2        ),
        .pc_D          ( pc_D          ),
        .instr_D       ( instr_D       ),
        .valid_D       ( valid_D       ),
        .pc_E          ( pc_E          ),
        .rd1_E         ( rd1_E         ),
        .rd2_E         ( rd2_E         ),
        .imm_E         ( imm_E         ),
        .rs1_E         ( rs1_E         ),
        .rs2_E         ( rs2_E         ),
        .rd_E          ( rd_E          ),
        .id_controls_E ( id_controls_E ),
        .valid_E       ( valid_E       )
    );

    // =========================================================================
    //  Execute Stage (EX) Signals & Instance
    // =========================================================================
    logic             ex_jfexe;
    Data_t            ex_alures;

    Data_t            alu_res_M;
    Data_t            rd2_M;
    RegAddr_t         rd_M;
    Addr_t            pc4_M;
    Id_controls_out_t id_controls_M;
    logic             valid_M;

    execute_stage execute_stage_inst (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .stall_ex      ( 1'b0          ),
        .flush_ex      ( 1'b0          ),
        .pc_E          ( pc_E          ),
        .rd1_E         ( rd1_E         ),
        .rd2_E         ( rd2_E         ),
        .imm_E         ( imm_E         ),
        .rs1_E         ( rs1_E         ),
        .rs2_E         ( rs2_E         ),
        .rd_E          ( rd_E          ),
        .id_controls_E ( id_controls_E ),
        .valid_E       ( valid_E       ),
        .ex_jfexe      ( ex_jfexe      ),
        .ex_alures     ( ex_alures     ),
        .alu_res_M     ( alu_res_M     ),
        .rd2_M         ( rd2_M         ),
        .rd_M          ( rd_M          ),
        .pc4_M         ( pc4_M         ),
        .id_controls_M ( id_controls_M ),
        .valid_M       ( valid_M       )
    );

    // =========================================================================
    //  Memory Stage (MEM) Signals & Instance
    // =========================================================================
    Data_t            alu_res_W;
    Data_t            dmem_data_W;
    RegAddr_t         rd_W;
    Addr_t            pc4_W;
    Id_controls_out_t id_controls_W;
    logic             valid_W;

    memory_stage memory_stage_inst (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .stall_mem     ( 1'b0          ),
        .flush_mem     ( 1'b0          ),
        .alu_res_M     ( alu_res_M     ),
        .rd2_M         ( rd2_M         ),
        .rd_M          ( rd_M          ),
        .pc4_M         ( pc4_M         ),
        .id_controls_M ( id_controls_M ),
        .valid_M       ( valid_M       ),
        .dmem_addr     ( dmem_addr     ),
        .dmem_byte_we  ( dmem_byte_we  ),
        .dmem_data_in  ( dmem_data_in  ),
        .dmem_data_out ( dmem_data_out ),
        .alu_res_W     ( alu_res_W     ),
        .dmem_data_W   ( dmem_data_W   ),
        .rd_W          ( rd_W          ),
        .pc4_W         ( pc4_W         ),
        .id_controls_W ( id_controls_W ),
        .valid_W       ( valid_W       )
    );

    // =========================================================================
    //  Writeback Stage (WB) Signals & Instance
    // =========================================================================
    writeback_stage writeback_stage_inst (
        .alu_res_W     ( alu_res_W     ),
        .dmem_data_W   ( dmem_data_W   ),
        .rd_W          ( rd_W          ),
        .pc4_W         ( pc4_W         ),
        .id_controls_W ( id_controls_W ),
        .valid_W       ( valid_W       ),
        .wb_rd         ( wb_rd         ),
        .wb_wd3        ( wb_wd3        ),
        .wb_we3        ( wb_rf_we3     )
    );

endmodule : cpu_core_m