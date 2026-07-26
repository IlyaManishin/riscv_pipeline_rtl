`timescale 1ns / 10ps

module Nexys4Top (
    input CLK100MHZ,
    input [15:0] SW,

    // sync signals (active low)
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);

  wire clk_pixel;
  wire clock_locked;
  reg  reset_pending = 1;
  reg  reset = 0;


  clock_gen video_clock_gen (
      .clk_out1(clk_pixel),  // output clk_out1
      .locked(clock_locked),  // output locked
      .clk_in1(CLK100MHZ)  // input clk_in1
  );


  vga_if video ();
  ram_if #(
      .ADDR_WIDTH(19),
      .DATA_WIDTH(8)
  ) vram ();



  video_pixel_bram dut_bram (
      .clka (CLK100MHZ),  // input wire clka
      .ena  (0),          // input wire ena
      .wea  (0),          // input wire [0 : 0] wea
      .addra(0),          // input wire [16 : 0] addra
      .dina (0),          // input wire [31 : 0] dina
      .clkb (CLK100MHZ),  // input wire clkb
      .addrb(vram.addr),  // input wire [18 : 0] addrb
      .doutb(vram.data)   // output wire [7 : 0] doutb
  );

  vga #(
      .ADDR_WIDTH(19),
      .ADDR_START(0),
      .HALF_RESOLUTION(1)
  ) vga_dut (
      .clk  (CLK100MHZ),
      .vclk (clk_pixel),
      .reset(reset | !clock_locked),

      .video(video.out),
      .vram (vram.reader)
  );

  always @(posedge CLK100MHZ) begin
    if (clock_locked & reset_pending) begin
      reset <= 1;
      reset_pending <= 0;
    end
    if (reset) reset <= 0;
  end

  assign VGA_R  = video.r;
  assign VGA_G  = video.g;
  assign VGA_B  = video.b;
  assign VGA_HS = video.hSync;
  assign VGA_VS = video.vSync;
endmodule
