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
    } hu_reg_indexes_t;


    // =========================================================================
    //  Hazard Unit Data & Control Inputs
    // =========================================================================

    typedef struct packed {
        logic reg_wr_E;  // from EX stage
        logic reg_wr_M;  // from MEM stage
        logic reg_wr_W;  // from WB stage
    } hu_regs_write_t;

    typedef struct packed {
        data_t wd_M;  // wd from MEM stage
        data_t wd_W;  // wd from WB stage
    } hu_write_data_t;


    // =========================================================================
    //  Forwarding Selectors & Output Structs
    // =========================================================================

    // Forwarding enable
    typedef enum logic {
        FWD_RF    = 1'b0,  // RegFile output
        FWD_STAGE = 1'b1   // Direct bypass
    } fwd_sel_t;

    // EX stage ALU mux selectors (One-hot encoded)
    typedef enum logic [2:0] {
        FWD_EX_RF  = 3'b100, // Pass Register File / Stage value
        FWD_EX_MEM = 3'b010, // Pass MEM stage data (wd_M)
        FWD_EX_WB  = 3'b001  // Pass WB stage data (wd_W)
    } fwd_ex_sel_t;

    // Forwarding unit bundled outputs
    typedef struct packed {
        // --- ID Stage Controls & Data ---
        fwd_sel_t id_fwd_sel1; // ID rd1 select
        fwd_sel_t id_fwd_sel2; // ID rd2 select
        data_t    id_fwd_wd;   // ID fwd data from WB

        // --- EX Stage Controls & Data ---
        fwd_sel_t ex_fwd_sel1; // EX fwd alu_in_a select
        fwd_sel_t ex_fwd_sel2; // EX fwd alu_in_b select
        data_t    ex_fwd_wd1;  // EX fwd alu_in_a data
        data_t    ex_fwd_wd2;  // EX fwd alu_in_b data
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