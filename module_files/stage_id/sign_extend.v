`include "../definitions.v"
`timescale 1ns / 1ps

module sign_extend (
    input  [`IMMEDIATE_WIDTH - 1:0] in,
    output [`ISA_WIDTH - 1:0] out
    );

    assign out = (in[`IMMEDIATE_WIDTH - 1] == 0)               ? 
                {{(`ISA_WIDTH - `IMMEDIATE_WIDTH){1'b0}}, in} : 
                {{(`ISA_WIDTH - `IMMEDIATE_WIDTH){1'b1}}, in};

endmodule