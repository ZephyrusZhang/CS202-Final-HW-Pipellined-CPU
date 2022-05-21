`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction decoding (id) stage
    execution (ex) stage
 */

module id_ex_reg (
    input clk, rst_n,

    input      id_hold,                                     // from hazard_unit (discard id result and pause ex)
    input      id_no_op,                                    // from if_id_reg (the operations of id have been stoped)
    output reg ex_no_op,                                    // for alu (stop opeartions)

    input      [`ISA_WIDTH - 1:0] id_pc_4,                  // from instruction_mem (the current program counter)
    output reg [`ISA_WIDTH - 1:0] ex_pc_4,                  // for ex_mem_reg

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
    input      [`ISA_WIDTH - 1:0] id_instruction,           // from if_id_reg (the current instruction)
    output reg [`ISA_WIDTH - 1:0] ex_operand_1,             // for alu (first oprand for alu)

    input      id_immediate_instruction,                    // from control_unit (whether it is a I type instruction)
    input      id_jump_instruction,                         // from control_unit (whether it is a J type instruction)

    input      [`ISA_WIDTH - 1:0] id_reg_2,                 // from general_reg (second register's value)
    input      [`ISA_WIDTH - 1:0] id_sign_extend_result,    // from sign_extend (16 bit sign extend result)
    output reg [`ISA_WIDTH - 1:0] ex_operand_2,             // for alu (second oprand for alu)

    output reg [`ISA_WIDTH - 1:0] ex_store_data,            // for ex_mem_reg (the data to be store into memory)

    input      [`REGISTER_SIZE - 1:0] id_src_reg_1,         // from if_id_reg (index of first source register)
    input      [`REGISTER_SIZE - 1:0] id_src_reg_2,         // from if_id_reg (index of second source register)
    input      [`REGISTER_SIZE - 1:0] id_dest_reg,          // from if_id_reg (index of destination resgiter)
    output reg [`REGISTER_SIZE - 1:0] ex_src_reg_1,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_src_reg_2,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_dest_reg,          // for (1) forwarding_unit
                                                            //     (2) hazrad_unit
                                                            //     (3) ex_mem_reg
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                ex_no_op,
                ex_pc_4,

                pc_offset,
                ex_reg_write_enable,
                  ex_mem_control,
                ex_alu_control,
                ex_operand_1,
                ex_operand_2,
                ex_store_data,
                ex_src_reg_1,
                ex_src_reg_2,
                ex_dest_reg
            }                   <= 0;
        end else if (id_hold | id_no_op)
            id_no_op            <= 1;
        else begin
            ex_no_op            <= 0;
            ex_pc_4             <= id_pc_4;

            pc_offset           <= id_condition_satisfied & id_branch_instruction;
            ex_reg_write_enable <= id_reg_write_enable;
            ex_mem_control      <= id_mem_control;
            ex_alu_control      <= id_alu_control;

            ex_operand_1        <= id_jump_instruction ? 
                                        {
                                            pc_4[`ISA_WIDTH - 1:`ISA_WIDTH - `ADDRES_WIDTH + 2],
                                            id_instruction[`ADDRES_WIDTH - 1:0], 
                                            2'b0
                                        }                                           : id_reg_1;
            ex_operand_2        <= id_immediate_instruction ? id_sign_extend_result : id_reg_2;
            ex_store_data       <= id_reg_2;

            ex_src_reg_1        <= id_src_reg_1;
            ex_src_reg_2        <= id_immediate_instruction ? 0 : id_src_reg_2;
            ex_dest_reg         <= id_dest_reg;
        end
    end
    
endmodule