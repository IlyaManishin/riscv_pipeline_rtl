`timescale 1ns / 10ps

module bram_image_tb;
  reg clk = 0;
  reg wr_clk = 0;

  reg reset;
  reg finished = 0;




  int fd;

  vga_if video ();
  ram_if #(
      .ADDR_WIDTH(19),
      .DATA_WIDTH(8)
  ) vram ();



  video_pixel_bram dut_bram (
      .clka (wr_clk),     // input wire clka
      .ena  (0),          // input wire ena
      .wea  (0),          // input wire [0 : 0] wea
      .addra(0),          // input wire [16 : 0] addra
      .dina (0),          // input wire [31 : 0] dina
      .clkb (wr_clk),     // input wire clkb
      .addrb(vram.addr),  // input wire [18 : 0] addrb
      .doutb(vram.data)   // output wire [7 : 0] doutb
  );

  vga #(.ADDR_START(0), .HALF_RESOLUTION(1)) vga_dut (
      .clk  (wr_clk),
      .vclk (clk),
      .reset(reset),

      .video(video),
      .vram (vram)
  );

  initial begin
    $display("Staring test");
    fd = $fopen("trace_bram_image.csv", "w");
    $fdisplay(fd, "hsync,vsync,r,g,b");

    fork
      begin
        while (!finished) begin
          #19.86 clk <= 1;
          #19.86 clk <= 0;
          $fdisplay(fd, "%d,%d,%d,%d,%d", video.hSync, video.vSync, video.r, video.g, video.b);
        end
      end
      begin
        while (!finished) begin
          #5 wr_clk <= 1;
          #5 wr_clk <= 0;
        end
      end
      begin
        reset = 1;
        #50 reset = 0;
        #90000000 finished = 1;
      end



    join

    $display("End test");
    $finish;

    $display("End test");
    $finish;
  end




endmodule
