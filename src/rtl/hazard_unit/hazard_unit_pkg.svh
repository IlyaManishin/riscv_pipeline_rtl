package hazard_unit_pkg;

    import risc_v_pkg::*;

    typedef struct packed {
        logic eq1_E; // Match: rs1 == rd_E
        logic eq2_E; // Match: rs2 == rd_E
        logic eq1_M; // Match: rs1 == rd_M
        logic eq2_M; // Match: rs2 == rd_M
        logic eq1_W; // Match: rs1 == rd_W
        logic eq2_W; // Match: rs2 == rd_W
    } rsi_cmp_t;

    typedef struct packed {
        reg_addr_t rs1;  // rs1 index from ID stage
        reg_addr_t rs2;  // rs2 index from ID stage
        reg_addr_t rd_E; // rd from EX stage
        reg_addr_t rd_M; // rd from MEM stage
        reg_addr_t rd_W; // rd from WB stage
    } rs_indexes_t;

    // Output control flags for pipeline stalls and flushes
    typedef struct packed {
        logic stall_pc;
        logic stall_if_id;
        logic flush_id_ex;
        logic flush_ex_mem;
    } hdu_controls_t;

endpackage : hazard_unit_pkg