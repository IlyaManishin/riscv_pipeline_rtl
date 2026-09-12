// =========================================================================
//  HU Behavior Defines
// =========================================================================

// Enables full WB->EX forwarding for dmem loads (uses full wb_wd instead of alu_out_W only)
// This define decreases CPI and ruins timings. 

`define USE_DMEM_WB_EX_FORWARDING


package hazard_unit_pkg;

    import risc_v_pkg::*;

    // =========================================================================
    //  Register Comparator & Index Structures
    // =========================================================================

    typedef struct packed {
        logic eq1_E; // rs1 == rd_E
        logic eq2_E; // rs2 == rd_E
        logic eq1_M; // rs1 == rd_M
        logic eq2_M; // rs2 == rd_M
        logic eq1_W; // rs1 == rd_W
        logic eq2_W; // rs2 == rd_W
        
        logic rd_E_valid; // rd_E != '0
        logic rd_M_valid; // rd_M != '0
        logic rd_W_valid; // rd_W != '0
    } rsi_cmp_t;

    typedef struct packed {
        reg_addr_t rs1;  // rs1 index from ID stage
        reg_addr_t rs2;  // rs2 index from ID stage
        reg_addr_t rd_E; // rd from EX stage
        reg_addr_t rd_M; // rd from MEM stage
        reg_addr_t rd_W; // rd from WB stage
    } hu_reg_idxs_t;


    // =========================================================================
    //  Hazard Unit Data & Control Inputs
    // =========================================================================

    typedef struct packed {
        logic reg_wr_E;  // from EX stage
        logic reg_wr_M;  // from MEM stage
        logic reg_wr_W;  // from WB stage
    } hu_regs_wr_t;

    typedef struct packed {
        data_t wd_M;        // wd from MEM stage
        data_t wd_W;        // wd from WB stage
        data_t alu_out_W;   // alu_out from WB stage (for partial WB->EX forwarding)
    } hu_wd_t;


    // =========================================================================
    //  Forwarding Selectors & Output Structs
    // =========================================================================

    // EX stage forwarding controls for precalculation
    typedef struct packed {
        logic fwd_en;     // 1: Enable forwarding to EX stage, 0: Use RF/Stage value
        logic mem_wb_sel; // 1: Forward MEM stage data (wd_M), 0: Forward WB stage data (wd_W)
    } fwd_ex_sel_t;

    // ID Stage Forwarding Controls
    typedef struct packed {
        logic  fwd_en1; // ID rd1 enable
        logic  fwd_en2; // ID rd2 enable
        data_t wd;      // ID fwd data from WB
    } fwd_id_controls_t;

    // EX Stage Forwarding Controls
    typedef struct packed {
        logic  fwd_en1; // EX fwd alu_in_a enable
        logic  fwd_en2; // EX fwd alu_in_b enable
        data_t wd1;     // EX fwd alu_in_a data
        data_t wd2;     // EX fwd alu_in_b data
    } fwd_ex_controls_t;

    // Combined Forwarding Output struct
    typedef struct packed {
        fwd_id_controls_t id;
        fwd_ex_controls_t ex;
    } fwd_controls_t;


    // =========================================================================
    //  HDU Control Signals
    // =========================================================================

    // Output control flags for pipeline stalls and flushes
    typedef struct packed {
        logic stall_pc;
        logic stall_if_id;
        logic flush_id_ex;
        logic flush_ex_mem;
    } hdu_controls_t;

endpackage : hazard_unit_pkg