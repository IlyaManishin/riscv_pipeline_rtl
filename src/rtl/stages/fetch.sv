`include "risc-v.svh"

module fetch_stage import risc_v_pkg::*;
(
    input  logic        clk,
    input  logic        rst,

//---------HAZARD UNIT WIRES----------
    input  logic        stall_pc,
    input  logic        stall_if_id,
    input  logic        flush_if_id,
//------------------------------------

//---------CONTROL & JUMP WIRES-------
    input  logic        jfexe_M,
    input  addr_t       jfpc_M,
//------------------------------------

//---------IMEM ACCESS----------------
    output addr_t       imem_addr,
    input  instr_t      instr,
//------------------------------------

//---------OUTPUT REGISTERS-----------
    output addr_t       pc_D,
    output instr_t      instr_D,
    output logic        valid_D
//------------------------------------
);

    // =========================================================================
    //  Internal Signals
    // =========================================================================

    addr_t pc;
    addr_t pc_next;
    logic  br_taken;
    addr_t pc_br;


// =========================================================================
    //  Branch Target & Jump Multiplexing
    // =========================================================================

    always_comb begin
        if (jfexe_M) begin
            br_taken = 1'b1;
            pc_br    = jfpc_M;
        end else begin
            br_taken = 1'b0;
            pc_br    = '0;
        end
    end


    // =========================================================================
    //  Submodules Instantiations
    // =========================================================================

    // --- Program Counter ---
    (* keep_hierarchy = `PC_KEEP_HIEARARCHY *)
    program_counter #(
        .PC_START_ADDR ( PC_START_ADDR )
    ) pc_inst (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .br_taken ( br_taken ),
        .pc_br    ( pc_br    ),
        .pc_stall ( stall_pc ),
        .pc       ( pc       ),
        .pc_next  ( pc_next  )
    );


    // =========================================================================
    //  IF / ID Pipeline Registers
    // =========================================================================

    assign imem_addr = pc_next;
    assign instr_D   = instr;

    always_ff @(posedge clk) begin
        if (flush_if_id) begin
            valid_D <= 1'b0;
            pc_D    <= 1'b0;
        end else if (rst) begin 
            valid_D <= 1'b1;
            pc_D    <= PC_START_ADDR;
        end else if (!stall_if_id) begin
            valid_D <= 1'b1;
            pc_D    <= pc_next;
        end
    end

endmodule : fetch_stage