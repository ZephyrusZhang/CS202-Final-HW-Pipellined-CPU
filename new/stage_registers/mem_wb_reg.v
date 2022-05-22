`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    memory (mem) stage
    write back (wb) stage
 */

module mem_wb_reg (
    input clk, rst_n,

    input      [1:0] hazard_control,                        // from hazard_unit [HAZD_HOLD_BIT] discard mem result
                                                            //                  [HAZD_NO_OP_BIT] pause wb stage
    input      mem_no_op,                                   // from ex_mem_reg (the operations of mem have been stopped)
    output reg wb_no_op,                                    // for general_reg (stop write opeartions)

    input      [`ISA_WIDTH - 1:0] mem_pc_4,                 // from ex_mem_reg (pc + 4)
    output reg [`ISA_WIDTH - 1:0] wb_pc_4,                  // for general_reg (to store into 31st register)

    input      mem_reg_write_enable,                        // from ex_mem_reg (whether it needs write to register)
    output reg wb_reg_write_enable,                         // for general_reg

    input      mem_mem_read_enable,                         // from ex_mem_reg (whether data is read from memory)
    output     wb_mem_read_enable,                          // for reg_write_select (to select data from memory)

    input      [`ISA_WIDTH - 1:0] mem_alu_result,           // from alu
    output reg [`ISA_WIDTH - 1:0] wb_alu_result,            // for (1) reg_write_select (result from alu)
                                                            //     (2) alu (forwarding)

    input      [`ISA_WIDTH - 1:0] mem_mem_read_data,        // from data_mem (data read)
    output reg [`ISA_WIDTH - 1:0] wb_mem_read_data,         // for reg_write_select (data from memory)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_dest_reg,   // from ex_mem_reg (index of destination resgiter)
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] wb_dest_reg     // for (1) forwarding_unit
                                                            //     (2) general_reg
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            {
                wb_no_op,
                wb_pc_4,

                wb_reg_write_enable,
                wb_mem_read_enable,
                wb_alu_result,
                wb_mem_read_data,
                wb_dest_reg
            }                   <= 0;
        end else if (hazard_control[HAZD_HOLD_BIT])
            wb_pc_4             <= wb_pc_4; // prevent auto latches
        else begin
            wb_pc_4             <= mem_pc_4;

            wb_reg_write_enable <= mem_reg_write_enable;
            wb_mem_read_enable  <= mem_mem_read_enable;
            wb_alu_result       <= mem_alu_result;
            wb_mem_read_data    <= mem_mem_read_data;
            wb_dest_reg         <= mem_dest_reg;
        end

        wb_no_op <= mem_no_op | hazard_control[HAZD_NO_OP_BIT];
    end
    
endmodule