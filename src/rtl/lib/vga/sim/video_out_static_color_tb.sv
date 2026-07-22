`timescale 1ns / 10ps


module video_out_static_color_tb;

  reg clk = 0;

  wire hsync;
  wire vsync;
  wire frameStart;
  wire visible;
  wire fifoRead;
  wire [3:0] r;
  wire [3:0] g;
  wire [3:0] b;

  int n_frames = 3;
  int fd;

  video_out dut_vout (
      8'b11111111,  // test pixel data
      visible,

      r,
      g,
      b
  );

  syncer dut_syncer (
      clk,
      0,  // not needed for this test
      0,  // not needed for this test
      fifoRead,  // not needed for this test
      hsync,
      vsync,
      visible
  );


  initial begin
    $display("Staring test");

    fd = $fopen("trace_static_color.csv", "w");
    $fdisplay(fd, "hsync,vsync,r,g,b");

    // TODO: should be 800*525
    for (int i = 0; i < n_frames * 800 * 600; i++) begin
      #19.86 clk = 1;
      #19.86 clk = 0;
      $fdisplay(fd, "%d,%d,%d,%d,%d", hsync, vsync, r, g, b);
    end

    $display("End test");
    $finish;
  end
endmodule
