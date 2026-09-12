//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:        
//
//  description:   
//------------------------------------------------------------------------------

`ifndef RISC_V_SVH
`define RISC_V_SVH

`timescale 1ns / 1ps

//==============================================================================
//    IMPLEMENTATION SPECIFIC COMPILE TIME DIRECTIVES - ONE SHOULD BE CAREFUL!
//==============================================================================

`define CFG_NAME_BASYS_3
`ifdef CFG_NAME_BASYS_3
    `define LED_NUM 16
`endif

//==============================================================================
//    DEBUG COMPILE TIME DIRECTIVES - ONE SHOULD BE CAREFUL!
//==============================================================================

//------------------------------------------------------------------------------
//    RISC_V_KEEP_HIEARARCHY
//
//    when defined  "yes" - (* keep_hierarchy = "yes" *)
//    wnen defined  "no"  - (* keep_hierarchy = "no" *)
//------------------------------------------------------------------------------

`define SYSTEM_KEEP_HIERARCHY "no"
`define STAGES_KEEP_HIEARARCHY "no"
`define HDU_KEEP_HIEARARCHY "no"
`define HU_KEEP_HIEARARCHY "no"
`define PC_KEEP_HIEARARCHY "no"

//------------------------------------------------------------------------------
`define IMEM_BRAM


//******************************************************************************
//******************************************************************************
package risc_v_pkg;

//=== common section
localparam int XLEN = 32;                            // RISC-V ISA dependent

localparam int IMEM_ADDR_BYTE_WIDTH = 14;            // (byte addressed) CPU system implementation dependent
localparam int DMEM_ADDR_BYTE_WIDTH = 14;            // (byte addressed) CPU system implementation dependent, 2^12 = 4KB

localparam int INSTR_LEN       = 32;                 // fixed for all RISC-V ISA except RVC
localparam int RF_ADDR_WIDTH   = 5;                  // RISC-V ISA dependent (?)

//--------------------------------------------------------------------------
localparam int DATA_BYTE_NUM   = XLEN / 8;
localparam int BYTE_ADDR_WIDTH = $clog2(DATA_BYTE_NUM);
localparam int DMEM_PORT_ADDR_WIDTH = DMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH;

//--------------------------------------------------------------------------
typedef logic [RF_ADDR_WIDTH-1:0]        reg_addr_t;
typedef logic [XLEN-1:0]                 data_t;
typedef logic [DATA_BYTE_NUM-1:0]        byte_data_ena_t;
typedef logic [7:0]                      byte_t;
typedef logic [BYTE_ADDR_WIDTH-1:0]      byte_addr_t;
typedef logic [INSTR_LEN-1:0]            instr_t;
typedef byte_t                           byte_data_t [DATA_BYTE_NUM];
typedef data_t                           addr_t;

`ifdef VIDEO_ENABLED
localparam addr_t PC_START_ADDR = 32'h2000_0000;
`else
//localparam Addr_t PC_START_ADDR = 32'H_0040_0000;
localparam addr_t PC_START_ADDR = 32'h0000_0000;
`endif

//=== ALU section 
localparam int ALU_SEL_LEN = 4;
typedef enum logic [ALU_SEL_LEN-1:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_AND  = 4'b0010,
    ALU_OR   = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SLT  = 4'b0101,
    ALU_SLTU = 4'b0110,
    ALU_LUI  = 4'b0111,
    ALU_JALR = 4'b1000,
    ALU_ANY  = 4'bxxxx   
} alu_sel_t;
//=== ALU section (end)

//=== SHIFTER section
typedef logic [$clog2(XLEN)-1:0] shift_shamt_t;

typedef enum logic [2:0] {
    SHIFT_SLL = 3'b100,
    SHIFT_SRL = 3'b010,
    SHIFT_SRA = 3'b001,
    SHIFT_ANY = 3'bxxx
} shift_sel_t;
//=== SHIFTER section (end)


//=== IMM_GEN section
`define IMM_GEN_DEFS_ENA
`ifdef IMM_GEN_DEFS_ENA

typedef logic [31:0] imm_t;
typedef logic [24:0] imm_input_t;
`endif
//=== IMM_GEN section (end)


//=== ID section 
`define ID_DEFS_ENA
/*
 * Instruction decoder instruction type.
 *
 * Passed as input argument into decoder instead of full instruction [31:0].
 * There's only 9 significant bits that are mandatory to determine instruction:
 * funct7[5], funct3[2:0], opcode[4:0] = [[31], [14], [13], [12], [6], [5], [4], [3], [2]]
 */

localparam int OPCODE_WIDTH = 5;

typedef struct packed {
    logic        funct7;               // [30] bit
    logic [2:0]  funct3;               // [14], [13], [12] bits
    logic [OPCODE_WIDTH-1:0]  opcode;  // [6], [5], [4], [3], [2] bits
    logic [1:0]  ones;                 // [1], [0] bits
} id_instr_t;


localparam int WB_SEL_LEN = 2;
typedef enum logic [WB_SEL_LEN-1:0] {
    WB_PC4_OUT     = 2'b00,
    WB_ALU_OUT     = 2'b01,
    WB_DMEM_OUT    = 2'b10,
    WB_ANY         = 2'bxx 
} wb_sel_t;


typedef struct packed {
    logic       dmem_we;
    logic [2:0] funct3;
} dmem_sel_t;


// instruction type
localparam int INSTR_TYPE_LEN = 3;
typedef enum logic [INSTR_TYPE_LEN-1:0] {
  //  INSTR_TYPE_R     = 3'b000,  <--- Not used
    INSTR_TYPE_I     = 3'b001,
    INSTR_TYPE_S     = 3'b010,
    INSTR_TYPE_B     = 3'b011,
    INSTR_TYPE_U     = 3'b100,
    INSTR_TYPE_J     = 3'b101,
    INSTR_TYPE_ANY   = 3'bxxx
} instr_type_t;

/*
 * Instruction decoder control output signals:
 *   - reg_wr       Write enable for Reg File (0: disable, 1: enable)
 *   - dmem_sel     Data memory access config: dmem_we (1 bit) + funct3 (3 bits)
 *   - a_sel        ALU operand A source (0: PC, 1: rd1)
 *   - b_sel        ALU operand B source (0: imm, 1: rd2)
 *   - sh_sel       Shift operation type (shift_sel_t enum)
 *   - br_un        Branch comparison type (0: signed, 1: unsigned)
 *   - pc_sel       Next PC source (0: ALU out, 1: PC+4)
 *   - alu_sel      ALU operation type (alu_sel_t enum)
 *   - wb_sel       Writeback source to RF (wb_sel_t enum)
 *   - instr_type   Decoded instruction format (instr_type_t enum)
 *   - br_unit_sel  Branch unit enable signal
 *   - alushift_sel Result selector (0: ALU, 1: Shifter)
 */
typedef struct packed {
    logic          reg_wr;
    dmem_sel_t     dmem_sel;
    logic          a_sel;
    logic          b_sel;
    shift_sel_t    sh_sel;
    logic          br_un;
    logic          pc_sel;
    alu_sel_t      alu_sel;
    wb_sel_t       wb_sel;
    instr_type_t   instr_type;
    logic          br_unit_sel;    
    logic          alushift_sel;
} id_controls_out_t;


`ifdef ID_DEFS_ENA
`endif
//=== ID section (end)

//===DMEM section
typedef enum logic [2:0] {
    LOAD_LB  = 3'b000,
    LOAD_LH  = 3'b001,
    LOAD_LW  = 3'b010,
    LOAD_LBU = 3'b100,
    LOAD_LHU = 3'b101
} load_instr_t;
//===DMEM section (end)

//=== UART section
localparam RV_BAUD_RATE  = 115200;
localparam RV_TIME_BASE  = 7;  // ns per system clock period
localparam RV_DATA_WIDTH = 8;

typedef enum logic[1:0] {
    TXSTATUS_ADDR = 2'h0,
    TXDATA_ADDR   = 2'h1,
    RXSTATUS_ADDR = 2'h2,
    RXDATA_ADDR   = 2'h3
} uart_map_addr_t;
//=== UART section (end)

endpackage : risc_v_pkg

`endif // RISC_V_SVH
