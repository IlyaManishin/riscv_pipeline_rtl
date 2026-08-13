`include "risc-v.svh"
//------------------------------------------------------------------------------
//  module: dmem_rd_byte_sel_m
//  Computes rd_port byte-select + sign/zero flag from byte_addr/funct3 only.
//  No dmem data involved -> lives one stage early (MEM), result pipelined.
//------------------------------------------------------------------------------
module dmem_rd_byte_sel_m import risc_v_pkg::*;
(
    input  logic [2:0]  funct3,
    input  ByteAddr_t   byte_addr,

    output RdByteSel_t  rd_byte_sel
);

always_comb begin
    rd_byte_sel.is_unsigned_read = funct3[2];

    unique case (funct3[1:0])
        2'b00: begin // LB/LBU
            rd_byte_sel.rd_lo_byte_sel = ByteDataEna_t'(1'b1) << byte_addr;
            rd_byte_sel.rd_hi_byte_sel = rd_byte_sel.rd_lo_byte_sel;
        end
        2'b01: begin // LH/LHU
            rd_byte_sel.rd_lo_byte_sel = ByteDataEna_t'(1'b1) << {byte_addr[1], 1'b0};
            rd_byte_sel.rd_hi_byte_sel = ByteDataEna_t'(1'b1) << {byte_addr[1], 1'b1};
        end
        default: begin // LW
            rd_byte_sel.rd_lo_byte_sel = '0;
            rd_byte_sel.rd_hi_byte_sel = '0;
        end
    endcase
end

endmodule : dmem_rd_byte_sel_m