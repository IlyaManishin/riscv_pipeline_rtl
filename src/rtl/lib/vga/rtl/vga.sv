`timescale 1ns / 10ps


interface vga_if;
  logic hSync, vSync;
  logic [3:0] r;
  logic [3:0] g;
  logic [3:0] b;

  modport in(input hSync, vSync, r, g, b);
  modport out(output hSync, vSync, r, g, b);
endinterface  //vga_signal


interface ram_if #(
    parameter int ADDR_WIDTH,
    parameter int DATA_WIDTH
);
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] data;

  modport ram(input addr, output data);
  modport reader(output addr, input data);
endinterface  //ram_if

module vga #(
    parameter ADDR_WIDTH = 19,
    parameter ADDR_START = 0,

    // video signal resolution
    parameter H_VISIBLE = 640,
    parameter V_VISIBLE = 480,

    // if 1, each pixel from the framebuffer will be shown 4 times
    // e.g. if video resolution is 640x480, image resolution will be 320x240
    parameter HALF_RESOLUTION = 0
) (
    input logic clk,
    input logic vclk,
    input logic reset,

    vga_if video,
    ram_if vram
);

  logic [8:0] fifo_out;
  logic [8:0] fifo_in;
  logic video_visible;
  logic fifo_rd_en;
  logic fifo_wr_en;
  logic fifo_full;

  logic fifo_wr_rst_busy, fifo_rd_rst_busy, fifo_empty;

  video_out vout (
      .pixel_data(fifo_out[7:0]),
      .visible(video_visible),
      .color_r(video.r),
      .color_g(video.g),
      .color_b(video.b)
  );

  syncer video_syncer (
      .clk(vclk),
      .rst(fifo_empty | fifo_rd_rst_busy),

      .frameStartFifo(fifo_out[8]),

      .fifoRead(fifo_rd_en),
      .visible (video_visible),

      .hSync(video.hSync),
      .vSync(video.vSync)
  );


  xpm_fifo_async #(
    .FIFO_READ_LATENCY(0),
    .FIFO_WRITE_DEPTH(64),
    .READ_DATA_WIDTH(9),
    .WRITE_DATA_WIDTH(9),
    .PROG_FULL_THRESH(40),
    .READ_MODE("fwft"),
    .SIM_ASSERT_CHK(1),
    .USE_ADV_FEATURES("0002")
  ) video_xpm_fifo (
    .rst(reset),

    .wr_clk(clk),
    .rd_clk(vclk),

    .din(fifo_in),
    .wr_en(fifo_wr_en),

    .dout(fifo_out),
    .rd_en(fifo_rd_en),

    .prog_full(fifo_full),

    // reset control
    .wr_rst_busy(fifo_wr_rst_busy),
    .rd_rst_busy(fifo_rd_rst_busy),
    .empty(fifo_empty)
  );

  vram_reader #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .ADDR_START(ADDR_START),
      .N_PIXELS  (HALF_RESOLUTION ? (H_VISIBLE * V_VISIBLE / 4) : (H_VISIBLE * V_VISIBLE)),
      .HALF_RESOLUTION(HALF_RESOLUTION)
  ) vram_reader (
      .clk(clk),
      .rst(reset | fifo_wr_rst_busy),
      .vram(vram),
      .fifo_full(fifo_full),
      .fifo_out(fifo_in),
      .fifo_write(fifo_wr_en)
  );
endmodule
