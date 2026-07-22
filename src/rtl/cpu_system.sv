//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       cpu_system (core and uncore)
//
//  description:   - RISC-V processor (RV32I ISA) single-cycle uArch
//                 - core and uncore parts
//                 - hardware platform (development board) for standalone RISC-V processor test
//------------------------------------------------------------------------------

`include "risc-v.svh"
`include "mem_init_path.svh"
`include "video_config.svh"
//******************************************************************************
//******************************************************************************
module cpu_system
  import risc_v_pkg::*;

(
    //--------------------------------------------------------------------------
`ifdef CFG_NAME_BASYS_3
    output logic [`LED_NUM-1:0] led,
`endif

`ifdef VIDEO_ENABLED
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS,

    input BTNC,
    input BTNU,
    input BTNL,
    input BTNR,
    input BTND,
`endif

    input logic ref_clk,
    input  wire uart_rxd,
    output wire uart_txd
);

  //timeunit      1ns;
  //timeprecision 1ps;

  //==============================================================================

  logic         cpu_clk;
  logic         rst;
  logic         pll_locked;

  logic         pixel_clk;
  Addr_t        imem_addr;
  Instr_t       instr;

  logic         dmem_ena;
  logic         vram_ena;
  logic         uart_ena;

  ByteDataEna_t dmem_byte_we;
  Addr_t        dmem_addr;
  Data_t        dmem_wdata;
  Data_t        dmem_rdata;
  Data_t        data_to_cpu;

  logic         rst_strobe = 1'b0;
  logic         cpu_rst;

  assign cpu_rst = rst | rst_strobe;

  // 128 Mb regions
  assign dmem_ena = dmem_addr[XLEN-1-:4] == 4'b0000;
  assign vram_ena = dmem_addr[XLEN-1-:4] == 4'b0001;
  assign buttons_ena = dmem_addr[(XLEN-1)-:(XLEN-2)] == 30'b00110000_00000000_000000;
  assign uart_ena = dmem_addr[31:28] == 4'b0010;

  //==============================================================================
`ifdef SIMULATOR
  str_t asm_instr;
  assign asm_instr = disasm(instr);
`endif

  //==============================================================================

  //---
  //(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY  *)
  pll pll_inst (
      .clk_in   (ref_clk),
      .clk_out1 (cpu_clk),
`ifdef VIDEO_ENABLED
      .clk_video(pixel_clk),
`endif
      .locked   (pll_locked)
  );

  //--- reset (related to clk)
  (* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
  rst_m rst_inst (
      .clk(cpu_clk),
      .ena(pll_locked),
      .rst(rst)
  );

  //---    risc-v cpu core
  (* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
  cpu_core_m cpu (
      //---
      .clk(cpu_clk),
      .rst(cpu_rst),

      //--- imem interface
      .imem_addr(imem_addr),
      .instr    (instr),

      //--- dmem interface
      .dmem_addr    (dmem_addr),
      .dmem_byte_we (dmem_byte_we),
      .dmem_data_in (dmem_wdata),
      .dmem_data_out(data_to_cpu)
  );

  //--------------------- instruction memory (IMEM) -------------------------
`ifndef IMEM_BRAM
  (* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
  imem_lutram #(
      .INIT_FILE (`IMEM_INIT_FILE),
      .ADDR_WIDTH(IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH)
  ) imem_inst (
      .addr (imem_addr[2+:(IMEM_ADDR_BYTE_WIDTH-BYTE_ADDR_WIDTH)]),
      .instr(instr)
  );

`else
  (* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
  imem_bram #(
      .INIT_FILE (`IMEM_INIT_FILE),
      .ADDR_WIDTH(IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH)
  ) imem_inst (
      .clk  (cpu_clk),
      .addr (imem_addr[2+:(IMEM_ADDR_BYTE_WIDTH-BYTE_ADDR_WIDTH)]),
      .instr(instr)
  );
`endif  // IMEM_BRAM


  //--------------------- data memory (DMEM) --------------------------------
  (* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
  dual_port_mem_m #(
      .INIT_FILE       (`DMEM_INIT_FILE),
      .PORTA_ADDR_WIDTH(DMEM_PORT_ADDR_WIDTH),
      .PORTB_ADDR_WIDTH(DMEM_PORT_ADDR_WIDTH)
  ) dmem_inst (
      //--- port A
      .clka (cpu_clk),
      .ena  (1),
`ifdef VIDEO_ENABLED
      .wea  (dmem_byte_we & {4{dmem_ena}}),
`else
      .wea  (dmem_byte_we),
`endif
      .addra(dmem_addr[2+:DMEM_PORT_ADDR_WIDTH]),
      .dina (dmem_wdata),
      .douta(dmem_rdata),
      //--- port B not connected
      .clkb (cpu_clk),
      .enb  (1'b0),
      .web  (4'b0),
      .addrb('0),
      .dinb ('0),
      .doutb()
  );


  Data_t uart_rdata;
`ifdef VIDEO_ENABLED
  assign data_to_cpu = dmem_ena ? dmem_rdata :
                       uart_ena ? uart_rdata : 
                       buttons_ena ? {{27'h0, BTNC, BTND, BTNL, BTNR, BTNU}} : 
                       32'h0;
`else
  assign data_to_cpu = uart_ena ? uart_rdata : dmem_rdata;
`endif

  // ------------------ uart subsystem -------------------------------------
  logic [1:0]   uart_reg_offset;
  assign uart_reg_offset = dmem_addr[3:2];
  uart_mmio_wrapper uart_inst (
      .clk(cpu_clk),
      .rst(cpu_rst),
    
      .RXD(uart_rxd),
      .TXD(uart_txd),
    
      .byte_we(dmem_byte_we),
      .reg_addr(uart_reg_offset),
      .wdata(dmem_wdata),
      .rdata(uart_rdata)
  );


  // ------------------ video subsystem -------------------------------------
`ifdef VIDEO_ENABLED
  localparam int VIDEO_RAM_WRITE_ADDR_WIDTH = `VIDEO_HALF_RESOLUTION ? 15 : 17;
  localparam int VIDEO_RAM_READ_ADDR_WIDTH = VIDEO_RAM_WRITE_ADDR_WIDTH + 2;

  logic [1:0] video_reset = 3;
  vga_if video ();
  ram_if #(
      .ADDR_WIDTH(VIDEO_RAM_READ_ADDR_WIDTH),
      .DATA_WIDTH(8)
  ) vram ();

  vga #(
      .ADDR_WIDTH(VIDEO_RAM_READ_ADDR_WIDTH),
      .ADDR_START(0),
      .HALF_RESOLUTION(`VIDEO_HALF_RESOLUTION)
  ) vga_dut (
      .clk  (cpu_clk),
      .vclk (pixel_clk),
      .reset(video_reset != 0 & pll_locked),

      .video(video.out),
      .vram (vram.reader)
  );

  always @(posedge cpu_clk) begin
    if (pll_locked & (video_reset != 0)) begin
      video_reset <= video_reset - 1;
    end
  end

  assign VGA_R  = video.r;
  assign VGA_G  = video.g;
  assign VGA_B  = video.b;
  assign VGA_HS = video.hSync;
  assign VGA_VS = video.vSync;


  video_pixel_bram vram_inst (
      .clka (cpu_clk),                                   // input wire clka
      .ena  (1),                                         // input wire ena
      .wea  (dmem_byte_we & {4{vram_ena}}),              // input wire [3 : 0] wea
      .addra(dmem_addr[2+:VIDEO_RAM_WRITE_ADDR_WIDTH]),  // input wire [16 : 0] addra
      .dina (dmem_wdata),                                // input wire [31 : 0] dina
      .clkb (cpu_clk),                                 // input wire clkb
      .addrb(vram.addr),                                 // input wire [18 : 0] addrb
      .doutb(vram.data)                                  // output wire [7 : 0] doutb
  );
`endif

  //--------------------- simplest port -------------------------------------
  localparam logic [DMEM_PORT_ADDR_WIDTH:0] LED_PORT_ADDR = {
    1'b1, {DMEM_PORT_ADDR_WIDTH{1'b0}}, 2'b00
  };  // { 1 - high bit, DMEM_PORT_ADDR_WIDTH-width zeros, 2-low-zeros }

  always_ff @(posedge cpu_clk) begin
    if (cpu_rst) begin
      led <= '0;
    end else begin
      if (dmem_byte_we == 4'b1111) begin
        if (dmem_addr[0+:(DMEM_PORT_ADDR_WIDTH+1)] == LED_PORT_ADDR) begin
          led <= dmem_wdata[`LED_NUM-1:0];
        end
      end
    end
  end

endmodule : cpu_system;
