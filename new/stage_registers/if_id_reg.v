`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction fetch (if) stage
    instruction decoding (id) stage
 */

module if_id_reg (
    input clk, rst_n,

    input [`ISA_WIDTH - 1:0] if_pc,                 // from instruction_mem (the current program counter)
    input [`ISA_WIDTH - 1:0] if_instruction,        // from instruction_mem (the current instruction)

    input pc_offset,                                // from id_ex_reg (from control_unit)
    
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