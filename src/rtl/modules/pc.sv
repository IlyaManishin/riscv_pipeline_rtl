`include "risc-v.svh"

module program_counter import risc_v_pkg::*;
#(
    parameter Addr_t PC_START_ADDR = '0
)
(
    input  logic clk,
    input  logic rst, // active high
    
    //-----Branch-----
    input  logic  br_taken,
    input  Addr_t pc_br,

    //-----Stall-----
    input  logic  pc_stall,

    output Addr_t pc,
    output Addr_t pc_next
);

    timeunit      1ns;
    timeprecision 1ps;

    always_comb begin
        if (rst) begin
            pc_next = PC_START_ADDR;
        end else if (pc_stall) begin
            pc_next = pc;
        end else if (br_taken) begin
            pc_next = pc_br;
        end else begin
            pc_next = pc + 4;
        end
    end

    always_ff @(posedge clk) begin
        pc <= pc_next;
    end

endmodule : program_counter;
