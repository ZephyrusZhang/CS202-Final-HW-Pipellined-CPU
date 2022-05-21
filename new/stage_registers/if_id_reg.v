`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction fetch (if) stage
    instruction decoding (id) stage
 */

module if_id_reg (
    input clk, rst_n,

    input      [`ISA_WIDTH - 1:0] if_pc_4,          // from instruction_mem (pc + 4)
    input      [`ISA_WIDTH - 1:0] if_instruction,   // from instruction_mem (the current instruction)

    input      pc_offset,                           // from id_ex_reg (from control_unit)
    
    input      if_hold,                             // from hazard_unit (discard if result and pause id)
    input      if_no_op,                            // from instruction_mem (the operations of if have been stoped)
    output reg id_no_op,                            // for general_reg (stop opeartions)

    output reg [`ISA_WIDTH - 1:0] id_pc_4,          // for id_ex_reg
    output reg [`ISA_WIDTH - 1:0] id_instruction    // for control_unit (the current instruction)
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                id_no_op,

                id_pc_4,
                id_instruction
            }              <= 0;
        end else if (if_hold | pc_offset | if_no_op) 
            id_no_op       <= 1;
        else begin
            id_no_op       <= 0;

            id_pc_4        <= if_pc_4;
            id_instruction <= if_instruction;
        end
    end
    
endmodule