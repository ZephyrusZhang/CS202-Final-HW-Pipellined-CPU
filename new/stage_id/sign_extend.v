`include "../definitions.v"
`timescale 1ns / 1ps

module sign_extend (
    input [`IMMEDIATE_WIDTH - 1 : 0] in,
    output [`ISA_WIDTH - 1 : 0] out
);

assign out = (in[`IMMEDIATE_WIDTH - 1] == 0) ? {16'b0000_0000_0000_0000, in} : {16'b1111_1111_1111_1111, in};

endmodule