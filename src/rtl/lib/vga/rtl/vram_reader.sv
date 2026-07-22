`timescale 1ns / 10ps


module vram_reader #(
    parameter int ADDR_WIDTH = 19,
    parameter int ADDR_START = 0,
    parameter int N_PIXELS   = 640 * 480,

    parameter int HALF_RESOLUTION = 0,
    parameter int H_VISIBLE = 640
) (
    input logic clk,
    input logic rst,

    ram_if.reader vram,

    input logic fifo_full,
    output logic [8:0] fifo_out,
    output logic fifo_write
);
  // registers for half resolution
  logic [10:0] current_pixel;
  logic do_repeat;
  logic [$bits(vram.addr)-1:0] repeat_addr;
  logic first_line;

  // TODO: make this configurable
  logic [3:0] ram_delay = 0;

  // TODO: reset
  initial begin
    vram.addr = ADDR_START;
  end

  logic fifo_was_full = 0;

  wire  ramping_up = !fifo_full & !fifo_was_full & ram_delay != 2;
  wire  writing = !fifo_full & ram_delay == 2;
  wire  wrapping_up = (fifo_full | fifo_was_full) & ram_delay != 0;

  wire  increase_addr = ramping_up | writing;

  assign fifo_write = wrapping_up | writing;
  assign fifo_out = {
    HALF_RESOLUTION ?
      vram.addr == first_line && current_pixel == ram_delay
      : vram.addr == (ADDR_START + ram_delay),
    vram.data
  };

  always @(posedge clk) begin
    if (rst) begin
      ram_delay = 0;
      fifo_was_full = 0;
      vram.addr = ADDR_START;
      if (HALF_RESOLUTION) begin
        current_pixel <= 0;
        do_repeat <= 1;
        repeat_addr <= ADDR_START;
        first_line <= 1;
      end
    end else begin
      if (increase_addr) begin
        if (HALF_RESOLUTION) begin
          current_pixel <= current_pixel == H_VISIBLE - 1 ? 0 : current_pixel + 1;
          // do it every other pixel
          if (current_pixel[0]) begin
            // repeat the line
            if (current_pixel == H_VISIBLE - 1 && do_repeat) begin
              vram.addr <= repeat_addr;
              first_line <= 0;
            end else begin
              vram.addr <= vram.addr == (ADDR_START + N_PIXELS - 1) ? ADDR_START : vram.addr + 1;
              if (vram.addr == (ADDR_START + N_PIXELS - 1)) begin
                first_line <= 1;
              end
            end
            // flip do_repeat
            if (current_pixel == H_VISIBLE - 1) begin
              do_repeat <= !do_repeat;
            end
          end
          if (current_pixel == 0) begin
            repeat_addr <= vram.addr;
          end
        end else begin
          vram.addr <= vram.addr == (ADDR_START + N_PIXELS - 1) ? ADDR_START : vram.addr + 1;
        end
      end

      if (ramping_up) ram_delay <= ram_delay + 1;
      if (wrapping_up) ram_delay <= ram_delay - 1;

      if (fifo_full) fifo_was_full <= 1;
      if (ram_delay == 0) fifo_was_full <= 0;
    end
  end
endmodule
