`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    execution (ex) stage
    memory (mem) stage
 */

module id_ex_reg (
    input clk, rst_n,

    input      ex_hold,                                     // from hazard_unit (discard id result and pause ex)
    output reg mem_no_op,                                   // for alu (stop opeartions)

    input      [`ISA_WIDTH - 1:0] ex_pc,                    // from instruction_mem (the current program counter)
    output reg [`ISA_WIDTH - 1:0] mem_pc,                   // for ex_mem_reg

    input      id_condition_satisfied,                      // from condition_check (whether the branch condition is met)
    input      id_branch_instruction,                       // from control_unit (whether it is a branch instruction)
    output reg pc_offset,                                   // for if_id_reg (whether the branch is taken)

    input      id_reg_write_enable,                         // from control_unit (whether it needs to read from memory)
    output reg ex_reg_write_enable,                         // for ex_mem_reg (whether it needs to read from memory)

    input      [1:0] id_mem_control,                        // from control_unit ([0] write, [1] read)
    output reg [1:0] ex_mem_control,                        // for ex_mem_reg

    input      [`ALU_CONTROL_WIDTH - 1:0] id_alu_control,   // from control_unit (alu control signals)
    output reg [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control,   // for alu

    input      [`ISA_WIDTH - 1:0] id_reg_1,                 // from general_reg (first register's value)
    output reg [`ISA_WIDTH - 1:0] ex_operand_1,             // for alu (first oprand for alu)

    input      id_immediate_instruction,                    // from control_unit (whether it is a I type instruction)
    input      [`ISA_WIDTH - 1:0] id_reg_2,                 // from general_reg (second register's value)
    input      [`ISA_WIDTH - 1:0] id_sign_extend_result,    // from sign_extend (16 bit sign extend result)
    output reg [`ISA_WIDTH - 1:0] ex_operand_2,             // for alu (second oprand for alu)

    input      [`REGISTER_SIZE - 1:0] id_src_reg_1,         // from if_id_reg (index of first source register)
    input      [`REGISTER_SIZE - 1:0] id_src_reg_2,         // from if_id_reg (index of second source register)
    input      [`REGISTER_SIZE - 1:0] id_dest_reg,          // from if_id_reg (index of destination resgiter)
    output reg [`REGISTER_SIZE - 1:0] ex_src_reg_1,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_src_reg_2,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_dest_reg,          // for forwarding_unit and hazrad_unit
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                ex_no_op,
                ex_pc,

                pc_offset,
                ex_reg_write_enable,
                ex_mem_control,
                ex_alu_control,
                ex_operand_1,
                ex_operand_2,
                ex_src_reg_1,
                ex_src_reg_2,
                ex_dest_reg
            }                   <= 0;
        end else if (~(if_hold | pc_offset)) begin
            ex_no_op            <= 0;
            ex_pc               <= id_pc;

            pc_offset           <= id_condition_satisfied & id_branch_instruction;
            ex_reg_write_enable <= id_reg_write_enable;
            ex_mem_control      <= id_mem_control;
            ex_alu_control      <= id_alu_control;

            ex_operand_1        <= id_reg_1;
            ex_operand_2        <= id_immediate_instruction ? id_sign_extend_result : id_reg_2;

            ex_src_reg_1        <= id_src_reg_1;
            ex_src_reg_2        <= id_immediate_instruction ? 0 : id_src_reg_2;
            ex_dest_reg         <= id_dest_reg;
        end else
            id_no_op            <= 1;
    end
    
endmodule