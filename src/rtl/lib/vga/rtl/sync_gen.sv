`timescale 1ns / 10ps

module sync_gen #(
    parameter int VISIBLE,
    parameter int FP,
    parameter int SYNC,
    parameter int BP

) (
    input logic clk,
    input logic en,

    output reg  sync,
    output reg  visible,
    output wire start
);

  reg [9:0] counter = 0;


  initial begin
    sync <= 1;
    visible <= 1;
  end


  wire count_end = counter == VISIBLE + FP + SYNC + BP - 1;

  assign start = counter == 0;

  always @(posedge clk) begin
    if (en) begin
      counter <= count_end ? 0 : counter + 1;
      if (counter == count_end) visible <= 1;
      if (counter == VISIBLE) visible <= 0;
      if (counter == VISIBLE + FP) sync <= 0;
      if (counter == VISIBLE + FP + SYNC) sync <= 1;
    end
  end

endmodule
