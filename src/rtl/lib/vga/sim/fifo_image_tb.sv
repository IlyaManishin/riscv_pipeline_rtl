`timescale 1ns / 10ps


module fifo_image_tb;

  reg clk = 0;
  reg wr_clk = 0;
  //   reg fifo_wr_en = 0;
  wire fifo_wr_en;
  reg fifo_reset = 0;
  reg resetting = 1;
  reg [7:0] image_data[640*480];

  wire hsync;
  wire vsync;
  wire frameStart;
  wire visible;
  wire [3:0] r;
  wire [3:0] g;
  wire [3:0] b;
  wire [8:0] fifo_out;
  wire [8:0] fifo_in;
  wire fifo_rd_en;
  wire fifo_full;
  wire fifo_wr_ack;

  int n_frames = 5;
  int fd, ifd;

  int send_x = 0;
  int send_y = 0;

  video_out dut_vout (
      fifo_out[7:0],  // test pixel data
      visible,

      r,
      g,
      b
  );

  syncer dut_syncer (
      clk,
      fifo_out[8],  // not needed for this test
      0,  // not needed for this test
      fifo_rd_en,  // not needed for this test
      hsync,
      vsync,
      visible
  );

  video_pixel_fifo dut_fifo (
      .rst      (fifo_reset),               // input wire rst
      .wr_clk   (wr_clk),                   // input wire wr_clk
      .rd_clk   (clk),                      // input wire rd_clk
      .din      (fifo_in),                  // input wire [8 : 0] din
      .wr_en    (fifo_wr_en & !resetting),  // input wire wr_en
      .rd_en    (fifo_rd_en & !resetting),  // input wire rd_en
      .dout     (fifo_out),                 // output wire [8 : 0] dout
      .prog_full(fifo_full),                // output wire full
      .wr_ack   (fifo_wr_ack)
      //   .empty(empty)    // output wire empty
  );


  initial begin
    $display("Staring test");

    $readmemh("../../../../../py_verify/test_patterns/box.png.bin", image_data);



    fd = $fopen("trace_fifo_image.csv", "w");
    $fdisplay(fd, "hsync,vsync,r,g,b");

    fifo_reset = 1;
    for (int i = 0; i < 50; i++) begin
      #19.86 clk = 1;
      #19.86 clk = 0;
    end
    fifo_reset = 0;

    for (int i = 0; i < 5; i++) begin
      #19.86 clk = 1;
      #19.86 clk = 0;
    end

    resetting = 0;


    for (int i = 0; i < n_frames * 800 * 525; i++) begin
      #19.86 clk = 1;
      #19.86 clk = 0;
      $fdisplay(fd, "%d,%d,%d,%d,%d", hsync, vsync, r, g, b);
    end

    $display("End test");
    $finish;
  end


  // image sender clock
  initial
    forever begin
      #5 wr_clk <= 1;
      #5 wr_clk <= 0;
    end
  // image sender
  assign fifo_in = {(send_x == 0 && send_y == 0), image_data[send_y*640+send_x]};
  always @(posedge wr_clk) begin
    // TODO: this is wrong

    if (!fifo_full) begin
      if (send_x == 640 - 1) begin
        send_x <= 0;
        if (send_y == 480 - 1) begin
          send_y <= 0;
        end else begin
          send_y <= send_y + 1;
        end
      end else begin
        send_x <= send_x + 1;
      end
    end

    // if (!fifo_full) begin
    //   fifo_wr_en <= 1;
    // end else begin
    //   fifo_wr_en <= 0;
    // end
  end
  assign fifo_wr_en = !fifo_full;



endmodule
