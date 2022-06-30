`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    memory (mem) stage
    write back (wb) stage
 */

module mem_wb_reg (
    input clk, rst_n,

    input      [`HAZD_CTL_WIDTH - 1:0] hazard_control,          // from hazard_unit (specifies the next state for wb stage)
    input      ignore_no_op,                                    // from hazard_unit (whether to ignore no_op from mem stage)

    input      mem_no_op,                                       // from ex_mem_reg (the operations of mem have been stopped)
    output reg wb_no_op,                                        // for general_reg (stop write opeartions)

    input      mem_reg_write_enable,                            // from ex_mem_reg (whether it needs write to register)
    output reg wb_reg_write_enable,                             // for general_reg

    input      mem_mem_read_enable,                             // from ex_mem_reg (whether data is read from memory)
    output reg wb_mem_read_enable,                              // for reg_write_select (to select data from memory)

    input      [`ISA_WIDTH - 1:0] mem_alu_result,               // from alu
    output reg [`ISA_WIDTH - 1:0] wb_alu_result,                // for (1) reg_write_select (result from alu)
                                                                //     (2) alu (forwarding)

    input      input_enable,                                    // from data_mem (whether data is read from user input)
    input      switch_enable,                                   // from input_unit (whether data is read from toggle switches)
    input      [`ISA_WIDTH - 1:0] mem_mem_read_data,            // from data_mem (data read from memory)
    input      [`ISA_WIDTH - 1:0] keypad_data,                  // from input_unit (data from user keypad input)
    input      [`SWITCH_CNT - 1:0] switch_map,                  // from toggle switches hardware directly
    output reg [`ISA_WIDTH - 1:0] wb_mem_read_data,             // for reg_write_select (data to write back)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_dest_reg_idx,   // from ex_mem_reg (index of destination resgiter)
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] wb_dest_reg_idx     // for (1) forwarding_unit
                                                                //     (2) general_reg
    );

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                wb_no_op,

                wb_reg_write_enable,
                wb_mem_read_enable,
                wb_alu_result,
                wb_mem_read_data,
                wb_dest_reg_idx
            }                           <= 0;
        end else begin
            case (hazard_control)
                `HAZD_CTL_NO_OP: 
                    wb_no_op            <= 1'b1;
                `HAZD_CTL_RETRY: 
                    wb_no_op            <= 1'b0;
                /* this is the `HAZD_CTL_NORMAL state */
                default        : begin
                    wb_no_op            <= mem_no_op & ~ignore_no_op;
                    
                    wb_reg_write_enable <= mem_reg_write_enable;
                    wb_mem_read_enable  <= mem_mem_read_enable;
                    wb_alu_result       <= mem_alu_result;
                    wb_dest_reg_idx     <= mem_dest_reg_idx;

                    if (input_enable & (~mem_no_op | ignore_no_op)) 
                        wb_mem_read_data <= switch_enable ? {{(`ISA_WIDTH - `SWITCH_CNT){1'b0}}, switch_map} : keypad_data;
                    else
                        wb_mem_read_data <= mem_mem_read_data;
                end
            endcase
        end
    end
    
endmodule