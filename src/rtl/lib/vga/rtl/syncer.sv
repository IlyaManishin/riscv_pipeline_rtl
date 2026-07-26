`timescale 1ns / 10ps

module syncer #(
    // horizontal timings (in pixels)
    parameter H_VISIBLE = 640,
    parameter H_FP = 16,
    parameter H_SYNC = 96,
    parameter H_BP = 48,
    // H_TOTAL = 800 pixels

    // vertical timings (in lines)
    parameter V_VISIBLE = 480,
    parameter V_FP = 10,
    parameter V_SYNC = 2,
    parameter V_BP = 33
    // V_TOTAL = 535 lines
) (
    input clk,
    input rst,

    input frameStartFifo,

    output fifoRead,
    output hSync,
    output vSync,
    output visible
);

  wire hVisible, vVisible;
  wire lineStart, frameStart;

  logic synced = 0;
  logic prevFrameStartFifo = 0;

  // TODO: make this correct
  assign fifoRead = ((synced & visible) | (!synced & !frameStartFifo)) & !rst;
  always @(posedge clk) begin
    if (rst) begin
        synced <= 0;
        prevFrameStartFifo <= 0;
    end else begin
      if (lineStart & frameStart & frameStartFifo) synced <= 1;  // got in sync
      if (!prevFrameStartFifo & frameStartFifo & !(lineStart & frameStart))
        synced <= 0;  // lost sync

      prevFrameStartFifo <= frameStartFifo;
    end


  end

  assign visible = hVisible & vVisible;

  sync_gen #(
      .VISIBLE(H_VISIBLE),
      .FP(H_FP),
      .SYNC(H_SYNC),
      .BP(H_BP)
  ) HSyncGen (
      .clk(clk),
      .en (1),

      .sync(hSync),
      .visible(hVisible),
      .start(lineStart)
  );

  sync_gen #(
      .VISIBLE(V_VISIBLE),
      .FP(V_FP),
      .SYNC(V_SYNC),
      .BP(V_BP)
  ) VSyncGen (
      .clk(clk),
      .en (lineStart),

      .sync(vSync),
      .visible(vVisible),
      .start(frameStart)
  );


endmodule
