`include "definitions.v"
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/15 15:21:28
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input [5:0] alu_opcode,
    input [31:0] a_input,
    input [31:0] b_input,
    output reg [31:0] alu_output
);

always @(alu_opcode or a_input or b_input) begin
    case (alu_opcode)
        `EXE_SLL: alu_output = a_input << b_input;                                // sll
        `EXE_SRL: alu_output = a_input >> b_input;                                // srl
        `EXE_SLLV: alu_output = a_input << b_input;                                // sllv
        `EXE_SRLV: alu_output = a_input >> b_input;                                // srlv
        `EXE_SRA: alu_output = a_input >>> b_input;                               // sra
        `EXE_SRAV: alu_output = a_input >>> b_input;                               // srav
        6'b10_0000: alu_output = $signed(a_input) + $signed(b_input);               // add
        6'b10_0001: alu_output = $unsigned(a_input) + $unsigned(b_input);           // addu
        6'b10_0010: alu_output = $signed(a_input) - $signed(b_input);               // sub
        6'b10_0011: alu_output = $unsigned(a_input) - $unsigned(b_input);           // subu
        6'b10_0100: alu_output = a_input & b_input;                                 // and
        6'b10_0101: alu_output = a_input | b_input;                                 // or
        6'b10_0110: alu_output = a_input ^ b_input;                                 // xor
        6'b10_0111: alu_output = ~(a_input | b_input);                              // nor
        6'b10_1010: alu_output = ($signed(a_input) < $signed(b_input)) ? 1 : 0;     // slt
        6'b10_1011: alu_output = ($unsigned(a_input) < $unsigned(b_input)) ? 1 : 0; // sltu
        6'b00_1000: alu_output = $signed(a_input) + $signed(b_input);               // addi
        6'b00_1001: alu_output = $unsigned(a_input) + $unsigned(b_input);           // addiu
        6'b00_1010: alu_output = ($signed(a_input) < $signed(b_input)) ? 1 : 0;     // slti
        6'b00_1011: alu_output = ($unsigned(a_input) < $unsigned(b_input)) ? 1 : 0; // sltiu
        6'b00_1100: alu_output = a_input & b_input;                                 // andi
        6'b00_1101: alu_output = a_input | b_input;                                 // ori
        6'b00_1110: alu_output = a_input ^ b_input;                                 // xori
        6'b00_1111: alu_output = {b_input[15:0], a_input[15:0]};                    // lui
        default:    alu_output = 0;                                                 // default
    endcase
end

endmodule
