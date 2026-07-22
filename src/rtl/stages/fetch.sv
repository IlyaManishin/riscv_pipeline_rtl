`include "risc-v.svh"

module fetch_stage import risc_v_pkg::*;
(
    input  logic        clk,
    input  logic        rst,

    input  logic        stall_if,
    input  logic        flush_if,

    input  logic        id_jfid,
    input  Addr_t       id_imm_pc,

    input  logic        ex_jfexe,
    input  Addr_t       ex_alures,

    output Addr_t       imem_addr,
    input  Instr_t      instr,

    output Addr_t       pc_D,
    output Instr_t      instr_D,
    output logic        valid_D
);

    Addr_t pc;
    Addr_t pc_next;
    logic  br_taken;
    Addr_t pc_br;

    always_comb begin
        if (ex_jfexe) begin
            br_taken = 1'b1;
            pc_br    = ex_alures;
        end else if (id_jfid) begin
            br_taken = 1'b1;
            pc_br    = id_imm_pc;
        end else begin
            br_taken = 1'b0;
            pc_br    = '0;
        end
    end

    program_counter #(
        .WIDTH         ( $bits(Addr_t) ),
        .PC_START_ADDR ( PC_START_ADDR )
    ) pc_inst (
        .clk      ( clk ),
        .rst      ( rst ),
        .br_taken ( br_taken ),
        .pc_br    ( pc_br ),
        .pc_stall ( stall_if ),
        .pc       ( pc ),
        .pc_next  ( pc_next )
    );

    assign imem_addr = pc_next;
    assign pc_D      = pc;
    assign instr_D   = instr;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_D <= 1'b0;
        end else if (flush_if) begin
            valid_D <= 1'b0;
        end else if (!stall_if) begin
            valid_D <= 1'b1;
        end
    end

endmodule : fetch_stage
