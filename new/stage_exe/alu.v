`include "../definitions.v"
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
        `EXE_SLL: alu_output = a_input << b_input;                                  // sll
        `EXE_SRL: alu_output = a_input >> b_input;                                  // srl
        `EXE_SLLV: alu_output = a_input << b_input;                                 // sllv
        `EXE_SRLV: alu_output = a_input >> b_input;                                 // srlv
        `EXE_SRA: alu_output = a_input >>> b_input;                                 // sra
        `EXE_SRAV: alu_output = a_input >>> b_input;                                // srav
        `EXE_ADD: alu_output = $signed(a_input) + $signed(b_input);                 // add
        `EXE_ADDU: alu_output = $unsigned(a_input) + $unsigned(b_input);            // addu
        `EXE_SUB: alu_output = $signed(a_input) - $signed(b_input);                 // sub
        `EXE_SUBU: alu_output = $unsigned(a_input) - $unsigned(b_input);            // subu
        `EXE_AND: alu_output = a_input & b_input;                                   // and
        `EXE_OR: alu_output = a_input | b_input;                                    // or
        `EXE_XOR: alu_output = a_input ^ b_input;                                   // xor
        `EXE_NOR: alu_output = ~(a_input | b_input);                                // nor
        `EXE_SLT: alu_output = ($signed(a_input) < $signed(b_input)) ? 1 : 0;       // slt
        `EXE_SLTU: alu_output = ($unsigned(a_input) < $unsigned(b_input)) ? 1 : 0;  // sltu
        `EXE_ADDI: alu_output = $signed(a_input) + $signed(b_input);                // addi
        `EXE_ADDIU: alu_output = $unsigned(a_input) + $unsigned(b_input);           // addiu
        `EXE_SLTI: alu_output = ($signed(a_input) < $signed(b_input)) ? 1 : 0;      // slti
        `EXE_SLTIU: alu_output = ($unsigned(a_input) < $unsigned(b_input)) ? 1 : 0; // sltiu
        `EXE_ANDI: alu_output = a_input & b_input;                                  // andi
        `EXE_ORI: alu_output = a_input | b_input;                                   // ori
        `EXE_XORI: alu_output = a_input ^ b_input;                                  // xori
        `EXE_LUI: alu_output = {b_input[15:0], a_input[15:0]};                      // lui
        default:    alu_output = 0;                                                 // default
    endcase
end

endmodule
