`include "risc-v.svh"

/*
 * Module: program_counter
 * Description: Updates the Program Counter (PC) for the RISC-V pipeline.
 *
 * Control Priority:
 *   1. Reset (rst) - active high
 *   2. Stall (pc_stall) - Priority is higher than any branch or jump
 *   3. Branch Taken (br_taken)
 *   4. Sequential Execution (pc + 4)
 */
module program_counter import risc_v_pkg::*;
#(
    parameter addr_t PC_START_ADDR = '0
)
(
    input  logic clk,
    input  logic rst,
    
    //-----Branch-----
    input  logic  br_taken,
    input  addr_t pc_br,

    //-----Stall------
    input  addr_t pc_last,
    input  logic  pc_stall,

    output addr_t pc,
    output addr_t pc_next
);

    timeunit      1ns;
    timeprecision 1ps;

    always_comb begin
        if (pc_stall) begin
            pc_next = pc_last;
        end else if (br_taken) begin
            pc_next = pc_br;
        end else begin
            pc_next = pc;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= PC_START_ADDR;
        end else begin
            pc <= pc_next + 4;
        end
    end

endmodule : program_counter