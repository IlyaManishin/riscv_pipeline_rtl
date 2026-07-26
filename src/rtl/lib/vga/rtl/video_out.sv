`timescale 1ns / 10ps

// default parameters for 640x480@60
module video_out (
    input [7:0] pixel_data,
    input visible,

    output [3:0] color_r,
    output [3:0] color_g,
    output [3:0] color_b
);
  // color encoding: RRR GGG BB
  // conversion repeats most significant bits
  // https://stackoverflow.com/questions/2442576/how-does-one-convert-16-bit-rgb565-to-24-bit-rgb888
  assign color_r = {pixel_data[7:5], pixel_data[7]} & {4{visible}};
  assign color_g = {pixel_data[4:2], pixel_data[4]} & {4{visible}};
  assign color_b = {pixel_data[1:0], pixel_data[1:0]} & {4{visible}};
endmodule
