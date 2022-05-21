`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction decoding (id) stage
    execution (ex) stage
 */

module id_ex_reg (
    input clk, rst_n,

    input [`ISA_WIDTH - 1:0] id_pc,                 // from instruction_mem (the current program counter)

    input id_condition_satisfied,                   // from condition_check (whether the branch condition is met)
    input id_branch_instruction,                    // from control_unit (whether it is a branch instruction)

    input id_reg_write_enable,                      // from control_unit (whether it needs to read from memory)
    input [1:0] id_mem_control,                     // from control_unit ([0] write, [1] read)
    input [`ALU_CONTROL_WIDTH - 1:0] id_alu_control,// from control_unit (alu control signals)

    input [`ISA_WIDTH:0] id_reg_1,                 // from general_reg (first register's value)

    input id_sign_extend_instruction,               // from control_unit (whether it is a I type instruction)
    input [`ISA_WIDTH:0] id_reg_2,                  // from general_reg (second register's value)
    input [`ISA_WIDTH:0] id_sign_extend_result,     // from sign_extend (16 bit sign extend result)

    input id_src_reg_num_1,
    input 

    output [`ISA_WIDTH:0] ex_operand_1,                     // for alu (first oprand for alu)
    output [31:0] ex_operand_2,                     // for alu (or general_reg)

    output pc_offset,                               // from id_ex_reg (from control_unit)
    
    input if_hold,                                  // from hazard_unit (discard if result and pause id)

    output reg id_no_op,                            // for general_reg and control_unit (stop opeartions)

    output reg [`ISA_WIDTH - 1:0] id_pc,            // for id_ex_reg
    output reg [`ISA_WIDTH - 1:0] id_instruction    // for control_unit (the current instruction)
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                id_no_op,

                id_pc,
                id_instruction
            }              <= 0;
        end else if (~(if_hold | pc_offset)) begin
            id_no_op       <= 0;

            id_pc          <= if_pc;
            id_instruction <= if_instruction;
        end else
            id_no_op       <= 1;
    end
    
endmodule