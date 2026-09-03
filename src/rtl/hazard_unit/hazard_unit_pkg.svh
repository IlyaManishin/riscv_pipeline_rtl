package hazard_unit_pkg;

    import risc_v_pkg::*;

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

    typedef struct packed {
        data_t wd_E; // wd from EX stage
        data_t wd_M; // wd from MEM stage
        data_t wd_W; // wd from WB stage
    } hu_write_data_t;

    // Output control flags for pipeline stalls and flushes
    typedef struct packed {
        logic stall_pc;
        logic stall_if_id;
        logic flush_id_ex;
        logic flush_ex_mem;
    } hdu_controls_t;

endpackage : hazard_unit_pkg