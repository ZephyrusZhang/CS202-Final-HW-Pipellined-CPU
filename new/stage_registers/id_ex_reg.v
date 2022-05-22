`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction decoding (id) stage
    execution (ex) stage
 */

module id_ex_reg (
    input clk, rst_n,

    input      [1:0] hazard_control,                        // from hazard_unit [HAZD_HOLD_BIT] discard id result
                                                            //                  [HAZD_NO_OP_BIT] pause ex stage
    input      id_no_op,                                    // from if_id_reg (the operations of id have been stoped)
    output reg ex_no_op,                                    // for alu (stop opeartions)

    // output reg [`ISA_WIDTH - 1:0] ex_pc,                  // for ex_mem_reg (to store into 31st register)

    input      i_type_instruction,                          // from control_unit (whether it is a I type instruction)
    input      r_type_instruction,                          // from control_unit (whether it is a R type instruction)
    input      j_instruction,                               // from control_unit (whether it is a jump instruction)
    input      jr_instruction,                              // from control_unit (whether it is a jr instruction)
    input      jal_instruction,                             // from control_unit (whether it is a jal insutrction)
    input      branch_instruction,                          // from control_unit (whether it is a branch instruction)
    input      store_instruction,                           // from control_unit (whether it is a strore instruction)

    input      condition_satisfied,                         // from condition_check (whether the branch condition is met)
    output reg pc_offset,                                   // for (1) if_id_reg (whether the branch is taken thus prediction failed)
                                                            //     (2) instruction_mem (whether the pc should be offsetted)
    output reg pc_overload,                                 // for (1) if_id_reg (whether a jump occured thus prediction failed)
                                                            //     (2) instruction_mem (whether the pc should be overloaded)

    input      id_reg_write_enable,                         // from control_unit (whether it needs write to register)
    output reg ex_reg_write_enable,                         // for ex_mem_reg

    input      [1:0] id_mem_control,                        // from control_unit ([0] write, [1] read)
    output reg [1:0] ex_mem_control,                        // for ex_mem_reg

    input      [`ALU_CONTROL_WIDTH - 1:0] id_alu_control,   // from control_unit (alu control signals)
    output reg [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control,   // for alu

    input      [`ISA_WIDTH - 1:0] id_reg_1,                 // from general_reg (first register's value)
    input      [`ISA_WIDTH - 1:0] id_instruction,           // from if_id_reg (the current instruction)
    input      [`ISA_WIDTH - 1:0] id_pc,                    // from if_id_reg (pc)
    output reg [`ISA_WIDTH - 1:0] ex_operand_1,             // for alu (first oprand for alu)

    input      [`ISA_WIDTH - 1:0] id_reg_2,                 // from general_reg (second register's value)
    input      [`ISA_WIDTH - 1:0] id_sign_extend_result,    // from sign_extend (16 bit sign extend result)
    output reg [`ISA_WIDTH - 1:0] ex_operand_2,             // for alu (second oprand for alu)

    output reg [`ISA_WIDTH - 1:0] ex_store_data,            // for ex_mem_reg (the data to be store into memory)

    input      [`REGISTER_SIZE - 1:0] id_reg_1_idx,         // from if_id_reg (index of first source register)
    input      [`REGISTER_SIZE - 1:0] id_reg_2_idx,         // from if_id_reg (index of second source register)
    input      [`REGISTER_SIZE - 1:0] id_reg_dest_idx,      // from if_id_reg (index of destination resgiter)
    output reg [`REGISTER_SIZE - 1:0] ex_reg_1_idx,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_reg_2_idx,         // for forwarding_unit
    output reg [`REGISTER_SIZE - 1:0] ex_reg_dest_idx,      // for (1) forwarding_unit
                                                            //     (2) hazrad_unit
                                                            //     (3) ex_mem_reg
    );

    wire i_type_abnormal = store_instruction | branch_instruction;
    wire j_type_normal   = j_instruction | jal_instruction;

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                ex_no_op,

                pc_offset,
                ex_reg_write_enable,
                ex_mem_control,
                ex_alu_control,
                ex_operand_1,
                ex_operand_2,
                ex_store_data,
                ex_reg_1_idx,
                ex_reg_2_idx,
                ex_reg_dest_idx
            }                   <= 0;
        end else if (hazard_control[HAZD_HOLD_BIT])
            ex_pc               <= ex_pc; // prevent auto latches
        else begin
            ex_pc               <= id_pc;

            pc_offset           <= condition_satisfied & branch_instruction;
            pc_overload         <= j_type_normal | jr_instruction;

            ex_reg_write_enable <= id_reg_write_enable;
            ex_mem_control      <= id_mem_control;
            ex_alu_control      <= id_alu_control;

            ex_operand_1        <= j_type_normal ? {
                                        pc_4[`ISA_WIDTH - 1:`ADDRES_WIDTH + 2],
                                        id_instruction[`ADDRES_WIDTH - 1:0], 
                                        2'b00
                                    } : id_reg_1; // for J type instruction address extension 
            ex_operand_2        <= i_type_instruction ? id_sign_extend_result : id_reg_2;
            ex_store_data       <= id_reg_2;

            ex_reg_1_idx        <= j_type_normal      ? 0 : id_reg_1_idx;
            ex_reg_2_idx        <= (r_type_instruction | i_type_abnormal) ? id_reg_2_idx : 0;

            case ({i_type_instruction, i_type_abnormal, jal_instruction, jr_instruction})
                4'b1000: ex_reg_dest_idx <= id_reg_2_idx;   // I type instruction
                4'b0100: ex_reg_dest_idx <= 0;              // store or branch instruction
                4'b0010: ex_reg_dest_idx <= 31;             // jump and link store to 31st register
                4'b0001: ex_reg_dest_idx <= id_reg_1_idx;   // jump register reterives from 1st register
                default: ex_reg_dest_idx <= id_reg_dest_idx;    // R type instruction
            endcase
            
        end

        ex_no_op <= hazard_control[HAZD_NO_OP_BIT] | id_no_op;
    end
    
endmodule