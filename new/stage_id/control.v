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
    input      [`OP_CODE_WIDTH - 1:0] opcode,
    input      [`FUNC_CODE_WIDTH - 1:0] func,
    output reg [`ALU_CONTROL_WIDTH - 1:0] alu_opcode,   
    output     [1:0] mem_control,
    output     i_type_instruction,
    output     r_type_instruction,
    output     j_instruction,
    output     jr_instruction,
    output     jal_instruction,
    output     shift_instruction,
    output     branch_instruction,
    output     store_instruction,
    output reg wb_en,
    output reg [`COND_TYPE_WIDTH - 1:0] condition_type
    );

    assign mem_control[`MEM_READ_BIT]  = (opcode == 6'b100011);
    assign mem_control[`MEM_WRITE_BIT] = (opcode == 6'b101011);

    assign i_type_instruction = (opcode[5:2] != 4'b0000);
    assign r_type_instruction = (opcode == 6'b000000);
    assign j_instruction      = (opcode == 6'b000010);
    assign jr_instruction     = (opcode == 6'b000000 & func == 6'b001000);
    assign jal_instruction    = (opcode == 6'b000011);
    assign branch_instruction = (opcode == 6'b000100 | opcode == 6'b000101);
    assign store_instruction  = (opcode == 6'b101011);
    assign shift_instruction  = (opcode == 6'b000000 & func[5:2] == 4'b0000);

    wire lw = (opcode == 6'b10_0011);
    wire sw = (opcode == 6'b10_1011);
    wire i_format_exe = (opcode[5:3] == 3'b001);

    always @(*) begin
        case ({r_type_instruction, jr_instruction, branch_instruction, lw, sw, i_format_exe, j_instruction, jal_instruction})
            8'b1000_0000: begin alu_opcode <= func;         wb_en <= 1; end     // R format and is not jr
            8'b1100_0000: begin alu_opcode <= `EXE_NO_OP;   wb_en <= 0; end     // R format and is jr
            8'b0010_0000: begin alu_opcode <= `EXE_NO_OP;   wb_en <= 0; end     // branch instruction
            8'b0001_0000: begin alu_opcode <= `EXE_ADD;     wb_en <= 1; end     // lw
            8'b0000_1000: begin alu_opcode <= `EXE_ADD;     wb_en <= 0; end     // sw
            8'b0000_0001: begin alu_opcode <= `EXE_ADD;     wb_en <= 1; end     // jal
            8'b0000_0010: begin alu_opcode <= `EXE_NO_OP;   wb_en <= 0; end     // j
            8'b0000_0100: begin alu_opcode <= opcode;       wb_en <= 1; end     // I format and is not branch and lw and sw
            default:      begin alu_opcode <= `EXE_NO_OP;   wb_en <= 0; end
        endcase
        case (opcode)
            6'b00_0100: condition_type <= `COND_TYPE_BEQ;
            6'b00_0101: condition_type <= `COND_TYPE_BNQ;
            default:    condition_type <= `NOT_BRANCH;
        endcase
    end

endmodule