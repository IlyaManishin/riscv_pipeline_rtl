`include "risc-v.svh"
//------------------------------------------------------------------------------
//  module: dmem_rd_port_m
//  Data-dependent part of the dmem read port: applies a precomputed
//  RdByteSel_t (from MEM stage) to the just-arrived data word.
//------------------------------------------------------------------------------
module dmem_rd_port_m import risc_v_pkg::*;
(
    input  logic [2:0]  funct3,
    input  RdByteSel_t  rd_byte_sel,

    input  Data_t       data_in,
    output Data_t       data_out
);

ByteData_t byte_data;
Byte_t     rd_lo_byte;
Byte_t     rd_hi_byte;
Byte_t     sign;

//------------------------------------------------------------------------------
//    Decompose word into bytes
//------------------------------------------------------------------------------
always_comb begin
    for (int i = 0; i < DATA_BYTE_NUM; i++) begin
        byte_data[i] = data_in[i*8 +: 8];
    end
end

//------------------------------------------------------------------------------
//    Select bytes via precomputed one-hot vectors (plain AND-OR mux)
//------------------------------------------------------------------------------
always_comb begin
    rd_lo_byte = '0;
    rd_hi_byte = '0;
    for (int i = 0; i < DATA_BYTE_NUM; i++) begin
        rd_lo_byte |= byte_data[i] & {8{rd_byte_sel.rd_lo_byte_sel[i]}};
        rd_hi_byte |= byte_data[i] & {8{rd_byte_sel.rd_hi_byte_sel[i]}};
    end
end

// sign extension
assign sign = rd_byte_sel.is_unsigned_read ? '0 : {8{rd_hi_byte[7]}};

//------------------------------------------------------------------------------
//    Assemble output
//------------------------------------------------------------------------------
always_comb begin
    case (funct3[1:0])
        2'b00:   data_out = {sign, sign, sign, rd_lo_byte};
        2'b01:   data_out = {sign, sign, rd_hi_byte, rd_lo_byte};
        2'b10:   data_out = data_in;
        default: data_out = data_in;
    endcase
end

endmodule : dmem_rd_port_m