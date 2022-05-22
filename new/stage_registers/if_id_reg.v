`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction fetch (if) stage
    instruction decoding (id) stage
 */

module if_id_reg (
    input clk, rst_n,
    
    input      [1:0] hazard_control,                        // from hazard_unit [HAZD_HOLD_BIT] discard if result
                                                            //                  [HAZD_NO_OP_BIT] pause id stage
    input      if_no_op,                            // from instruction_mem (the operations of if have been stoped)
    output reg id_no_op,                            // for general_reg (stop opeartions)

    input      [`ISA_WIDTH - 1:0] if_pc_4,          // from instruction_mem (pc + 4)
    output reg [`ISA_WIDTH - 1:0] id_pc_4,          // for id_ex_reg (to store into 31st register)

    input      [`ISA_WIDTH - 1:0] if_instruction,   // from instruction_mem (the current instruction)
    output reg [`ISA_WIDTH - 1:0] id_instruction    // for control_unit (the current instruction)

    input      pc_offset,                           // from id_ex_reg (if branch)    
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                id_no_op,

                id_pc_4,
                id_instruction
            }              <= 0;
        end else if (if_hold | pc_offset) 
            id_pc_4        <= id_pc_4; // prevent auto latches
        else begin
            id_pc_4        <= if_pc_4;
            id_instruction <= if_instruction;
        end

        id_no_op <= if_no_op |                         // previous stage have stopped
                    hazard_control[HAZD_NO_OP_BIT] |   // or hazard detected
                    pc_offset;                         // or branch taken hence the next instruction is not valid
    end
    
endmodule