`include "risc-v.svh"

module cpu_core_m import risc_v_pkg::*;
(
    input  logic         clk,
    input  logic         rst,

    // =========================================================================
    //  Instruction Memory Interface
    // =========================================================================
    output addr_t        imem_addr,
    input  instr_t       instr,

    // =========================================================================
    //  Data Memory Interface
    // =========================================================================
    output addr_t        dmem_addr,
    output byte_data_ena_t dmem_byte_we,
    output data_t        dmem_wdata,
    input  data_t        cpu_rdata
);

    // =========================================================================
    //  Register File Signals & Instance
    // =========================================================================
    reg_addr_t rs1;
    reg_addr_t rs2;
    data_t     rf_rd1;
    data_t     rf_rd2;

    reg_addr_t wb_rd;
    data_t     wb_wd3;
    logic      wb_rf_we3;

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
    //  Control & Jump Signals
    // =========================================================================
    logic  jfexe_M;
    addr_t jfpc_M;

    // =========================================================================
    //  Hazard Detection Unit Signals & Instance
    // =========================================================================
    logic stall_pc;
    logic stall_if_id;
    logic flush_id_ex;
    logic flush_ex_mem;

    logic ex_reg_wr;
    logic mem_reg_wr;

    assign ex_reg_wr  = id_controls_E.reg_wr;
    assign mem_reg_wr = id_controls_M.reg_wr;

    (* keep_hierarchy = `HDU_KEEP_HIEARARCHY *)
    hazard_detection_unit hazard_unit_inst (
        .id_rs1      ( rs1                  ),
        .id_rs2      ( rs2                  ),
        .jfexe_M     ( jfexe_M              ),
        .ex_reg_wr   ( ex_reg_wr            ),
        .ex_rd       ( rd_E                 ),
        .mem_reg_wr  ( mem_reg_wr           ),
        .mem_rd      ( rd_M                 ),
        .wb_reg_wr   ( wb_rf_we3            ),
        .wb_rd       ( wb_rd                ),
        .stall_pc    ( stall_pc             ),
        .stall_if_id ( stall_if_id          ),
        .flush_id_ex ( flush_id_ex          ),
        .flush_ex_mem( flush_ex_mem         )
    );

    // =========================================================================
    //  Fetch Stage (IF) Signals & Instance
    // =========================================================================
    addr_t  pc_D;
    instr_t instr_D;
    logic   valid_D;

    (* keep_hierarchy = `STAGES_KEEP_HIEARARCHY *)
    fetch_stage fetch_stage_inst (
        .clk          ( clk         ),
        .rst          ( rst         ),
        .stall_pc     ( stall_pc    ),
        .stall_if_id  ( stall_if_id ),
        .flush_if_id  ( 1'b0        ),
        .jfexe_M      ( jfexe_M     ),
        .jfpc_M       ( jfpc_M      ),
        .imem_addr    ( imem_addr   ),
        .instr        ( instr       ),
        .pc_D         ( pc_D        ),
        .instr_D      ( instr_D     ),
        .valid_D      ( valid_D     )
    );

    // =========================================================================
    //  Decode Stage (ID) Signals & Instance
    // =========================================================================
    addr_t                   pc_E;
    data_t                   rd1_E;
    data_t                   rd2_E;
    data_t                   imm_E;
    reg_addr_t               rs2_E;
    reg_addr_t               rd_E;
    logic [2:0]              funct3_E;
    id_controls_out_t        id_controls_E;
    logic                    valid_E;

    (* keep_hierarchy = `STAGES_KEEP_HIEARARCHY *)
    decode_stage decode_stage_inst (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .stall_id_ex   ( 1'b0          ),
        .flush_id_ex   ( flush_id_ex   ),
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
        .rs2_E         ( rs2_E         ),
        .rd_E          ( rd_E          ),
        .funct3_E      ( funct3_E      ),
        .id_controls_E ( id_controls_E ),
        .valid_E       ( valid_E       )
    );

    // =========================================================================
    //  Execute Stage (EX) Signals & Instance
    // =========================================================================
    data_t            alu_out_M;
    data_t            rd2_M;
    reg_addr_t        rd_M;
    addr_t            pc4_M;
    id_controls_out_t id_controls_M;
    logic             valid_M;

    (* keep_hierarchy = `STAGES_KEEP_HIEARARCHY *)
    execute_stage execute_stage_inst (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .stall_ex_mem  ( 1'b0          ),
        .flush_ex_mem  ( flush_ex_mem  ),
        .pc_E          ( pc_E          ),
        .rd1_E         ( rd1_E         ),
        .rd2_E         ( rd2_E         ),
        .imm_E         ( imm_E         ),
        .rs2_E         ( rs2_E         ),
        .rd_E          ( rd_E          ),
        .funct3_E      ( funct3_E      ),
        .id_controls_E ( id_controls_E ),
        .valid_E       ( valid_E       ),
        .jfexe_M       ( jfexe_M       ),
        .jfpc_M        ( jfpc_M        ),
        .alu_out_M     ( alu_out_M     ),
        .rd2_M         ( rd2_M         ),
        .rd_M          ( rd_M          ),
        .pc4_M         ( pc4_M         ),
        .id_controls_M ( id_controls_M ),
        .valid_M       ( valid_M       )
    );

    // =========================================================================
    //  Memory Stage (MEM) Signals & Instance
    // =========================================================================
    data_t            alu_out_W;
    data_t            cpu_rdata_W;
    reg_addr_t        rd_W;
    addr_t            pc4_W;
    id_controls_out_t id_controls_W;
    logic             valid_W;

    (* keep_hierarchy = `STAGES_KEEP_HIEARARCHY *)
    memory_stage memory_stage_inst (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .stall_mem_wb  ( 1'b0          ),
        .flush_mem_wb  ( 1'b0          ),
        .alu_out_M     ( alu_out_M     ),
        .rd2_M         ( rd2_M         ),
        .rd_M          ( rd_M          ),
        .pc4_M         ( pc4_M         ),
        .id_controls_M ( id_controls_M ),
        .valid_M       ( valid_M       ),
        .dmem_addr     ( dmem_addr     ),
        .dmem_byte_we  ( dmem_byte_we  ),
        .dmem_wdata    ( dmem_wdata    ),
        .cpu_rdata     ( cpu_rdata     ),
        .alu_out_W     ( alu_out_W     ),
        .cpu_rdata_W   ( cpu_rdata_W   ),
        .rd_W          ( rd_W          ),
        .pc4_W         ( pc4_W         ),
        .id_controls_W ( id_controls_W ),
        .valid_W       ( valid_W       )
    );

    // =========================================================================
    //  Writeback Stage (WB) Signals & Instance
    // =========================================================================
    (* keep_hierarchy = `STAGES_KEEP_HIEARARCHY *)
    writeback_stage writeback_stage_inst (
        .alu_out_W     ( alu_out_W     ),
        .cpu_rdata_W   ( cpu_rdata_W   ),
        .rd_W          ( rd_W          ),
        .pc4_W         ( pc4_W         ),
        .id_controls_W ( id_controls_W ),
        .valid_W       ( valid_W       ),
        .wb_rd         ( wb_rd         ),
        .wb_wd3        ( wb_wd3        ),
        .wb_we3        ( wb_rf_we3     )
    );

endmodule : cpu_core_m