`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the multiplexers between the id stage and id_ex_reg
 */

module id_ex_reg (
    input      i_type_instruction,                              // from control_unit (whether it is a I type instruction)
    input      r_type_instruction,                              // from control_unit (whether it is a R type instruction)
    input      j_instruction,                                   // from control_unit (whether it is a jump instruction)
    input      jr_instruction,                                  // from control_unit (whether it is a jr instruction)
    input      jal_instruction,                                 // from control_unit (whether it is a jal insutrction)
    input      branch_instruction,                              // from control_unit (whether it is a branch instruction)
    input      store_instruction,                               // from control_unit (whether it is a strore instruction)
    
    input      condition_satisfied,                             // from condition_check (whether the branch condition is met)
    output     pc_offset,                                       // for (1) if_id_reg (whether the branch is taken thus prediction failed)
                                                                //     (2) instruction_mem (whether the pc should be offsetted)
    output     pc_overload,                                     // for (1) if_id_reg (whether a jump occured thus prediction failed)
                                                                //     (2) instruction_mem (whether the pc should be overloaded)
    
    input      [`ISA_WIDTH - 1:0] id_reg_1,                     // from general_reg (first register's value)
    input      [`ISA_WIDTH - 1:0] id_pc,                        // from if_id_reg (pc)
    output     [`ISA_WIDTH - 1:0] mux_operand_1,                // for id_ex_reg (to pass on to alu)
    
    input      [`ISA_WIDTH - 1:0] id_reg_2,                     // from general_reg (second register's value)
    input      [`ISA_WIDTH - 1:0] id_sign_extend_result,        // from sign_extend (16 bit sign extend result)
    output     [`ISA_WIDTH - 1:0] mux_operand_2,                // for (1) id_ex_reg (to pass on to alu)
                                                                //     (2) instruction_mem (pc_offset_value)
    
    input      [`ISA_WIDTH - 1:0] id_instruction,               // from if_id_reg (the current instruction)
    output     [`ISA_WIDTH - 1:0] pc_overload_value,            // for instruction_mem (the value for pc to overloaded)
    
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_1_idx,       // from if_id_reg (index of first source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_2_idx,       // from if_id_reg (index of second source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_dest_idx,    // from if_id_reg (index of destination resgiter)
    output     [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx,      // for id_ex_reg (to pass on to forwarding_unit)
    output     [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx,      // for id_ex_reg (to pass on to forwarding_unit)
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx,   // for id_ex_reg
    
    output     reg_1_valid,                                     // for hazard_unit
    output     reg_2_valid                                      // for hazard_unit
    );

    wire i_type_abnormal = store_instruction | branch_instruction;
    wire j_type_normal   = j_instruction | jal_instruction;

    assign reg_1_valid = ~j_type_normal;
    assign reg_2_valid = r_type_instruction | i_type_abnormal;

    assign pc_offset         = condition_satisfied & branch_instruction;
    assign pc_overload       = j_type_normal | jr_instruction;
    assign pc_overload_value = j_type_normal ? {
                                    pc_4[`ISA_WIDTH - 1:`ADDRES_WIDTH + 2],
                                    id_instruction[`ADDRES_WIDTH - 1:0], 
                                    2'b00
                                } : id_reg_1; // for J type instruction address extension 

    assign mux_operand_1 = jal_instruction ? id_pc : id_reg_1;
    assign mux_operand_2 = i_type_instruction ? id_sign_extend_result : (
                           jal_instruction    ? 4                     : id_reg_2);

    assign mux_reg_1_idx = reg_1_valid ? id_reg_1_idx : 0;
    assign mux_reg_2_idx = reg_2_valid ? id_reg_2_idx : 0;

    always @(*) begin
        case ({i_type_instruction, i_type_abnormal, jal_instruction, jr_instruction})
            4'b1000: mux_reg_dest_idx <= id_reg_2_idx;       // I type instruction
            4'b0100: mux_reg_dest_idx <= 0;                  // store or branch instruction
            4'b0010: mux_reg_dest_idx <= 31;                 // jump and link store to 31st register
            4'b0001: mux_reg_dest_idx <= id_reg_1_idx;       // jump register reterives from 1st register
            default: mux_reg_dest_idx <= id_reg_dest_idx;    // R type instruction
        endcase
    end

    // assign mux_reg_dest_idx = select_dest({i_type_instruction, i_type_abnormal, jal_instruction, jr_instruction});
    // function [`REG_FILE_ADDR_WIDTH - 1:0] select_dest(input [3:0] reg selector);
    //     case (selector)
    //         4'b1000: select_dest = id_reg_2_idx;       // I type instruction
    //         4'b0100: select_dest = 0;                  // store or branch instruction
    //         4'b0010: select_dest = 31;                 // jump and link store to 31st register
    //         4'b0001: select_dest = id_reg_1_idx;       // jump register reterives from 1st register
    //         default: select_dest = id_reg_dest_idx;    // R type instruction
    //     endcase
    // endfunction
    
endmodule