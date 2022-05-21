`include "definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    memory (mem) stage
    write back (wb) stage
 */

module mem_wb_reg (
    input clk, rst_n,

    input mem_read_enable,                          // from ex_mem_reg (from control_unit)
    input mem_reg_write_enable,                     // from ex_mem_reg (from control_unit)

    input [`ISA_WIDTH - 1:0] mem_pc,                // from ex_mem_reg (the current progam counter)
    input [`ISA_WIDTH - 1:0] mem_read_data,         // from data_mem (from RAM or keypad)
    input [`ISA_WIDTH - 1:0] mem_alu_result,        // from ex_mem_reg (from alu)

    input mem_hold,                                 // from hazard_unit (discard mem result and pause wb)

    output reg wb_no_op,                            // for general_reg (stop write oepration)

    output reg wb_read_enable,                      //
    output reg wb_reg_write_enable,                 // for general_reg (update the resgister)

    output reg [`ISA_WIDTH - 1:0] wb_pc,
    output reg [`ISA_WIDTH - 1:0] wb_read_data,     // for id_ex_reg
    output reg [`ISA_WIDTH - 1:0] wb_alu_result     // for control_unit (the current instruction)
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                wb_no_op,
                
                wb_read_enable,
                wb_reg_write_enable,

                wb_pc,
                wb_read_data,
                wb_alu_result
            }                   <= 0;
        end else if (~mem_hold) begin
            wb_no_op            <= 0;
            
            wb_read_enable      <= mem_read_enable;
            wb_reg_write_enable <= mem_reg_write_enable;

            wb_pc               <= mem_pc;
            wb_read_data        <= mem_read_data;
            wb_alu_result       <= mem_alu_result;
        end else
            wb_no_op            <= 1;
    end
    
endmodule