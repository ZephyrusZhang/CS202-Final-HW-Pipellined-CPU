`include "../definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        opcode:     opcode of instruction
        func:       function code of instruction
        alu_opcode: to determine what operations the alu should execute
    Output:
        branch_en:      whether to branch
        mem_control:    control memory write and memory read
        i_type:         whether a I type instruction
        j_type:         whether a J type instruction
        offset:         tell PC to use offset. 1 => use
        overload:       tell PC to use overload, 1 => use
*/
module control (
    input [`OP_CODE_WIDTH - 1 : 0] opcode,
    input [`FUNC_CODE_WIDTH - 1 : 0] func,
    input rst_n,
    output reg [`ALU_CONTROL_WIDTH - 1:0] alu_opcode,   
    output reg branch_en,
    output reg[1:0] mem_control,
    output reg i_type,
    output reg j_type,
    output reg offset,
    output reg overload
);


endmodule