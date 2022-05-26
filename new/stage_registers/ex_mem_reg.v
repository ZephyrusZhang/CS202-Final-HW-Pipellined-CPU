`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    execution (ex) stage
    memory (mem) stage
 */

module ex_mem_reg (
    input clk, rst_n,

    input      [1:0] hazard_control,                        // from hazard_unit [HAZD_HOLD_BIT] discard ex result
                                                            //                  [HAZD_NO_OP_BIT] pause mem stage
    input      ex_no_op,                                    // from id_ex_reg (the operations of ex have been stoped)
    output reg mem_no_op,                                   // for alu (stop opeartions)

    input      [`ISA_WIDTH - 1:0] ex_pc_4,                  // from id_ex_reg (pc + 4)
    output reg [`ISA_WIDTH - 1:0] mem_pc_4,                 // for mem_wb_reg (to store into 31st register)

    input      ex_reg_write_enable,                         // from id_ex_reg (whether it needs write to register)
    output reg mem_reg_write_enable,                        // for mem_wb_reg

    input      [1:0] ex_mem_control,                        // from id_ex_reg ([MEM_WRITE_BIT] write, [MEM_READ_BIT] read)
    output reg [1:0] mem_mem_control,                       // for (1) data_mem: both read and write
                                                            //     (2) mem_wb_reg: only read

    input      [`ISA_WIDTH - 1:0] ex_alu_result,            // from alu
    output reg [`ISA_WIDTH - 1:0] mem_alu_result,           // for (1) data_mem (the read or write address)
                                                            //     (2) mem_wb_reg (the result of alu)
                                                            //     (3) alu (forwarding)

    input      [`FORW_SEL_WIDTH - 1:0] store_data_select,   // from forwarding_unit (select which data to store)
    input      [`ISA_WIDTH - 1:0] ex_store_data,            // from id_ex_reg (data read from rt register, for sw)
    input      [`ISA_WIDTH - 1:0] mem_alu_result_prev,      // from em_mem_reg (result of previous ex stage)
    input      [`ISA_WIDTH - 1:0] wb_reg_write_data,        // from reg_write_select (the data to write to general_reg)
    output reg [`ISA_WIDTH - 1:0] mem_store_data,           // for data_mem (the data to be stored)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_dest_reg,    // from id_ex_reg (index of destination resgiter)
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] mem_dest_reg    // for (1) forwarding_unit
                                                            //     (2) harard_unit
                                                            //     (3) mem_wb_reg
    );

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                mem_no_op,
                mem_pc_4,

                mem_reg_write_enable,
                mem_mem_control,

                mem_alu_result,
                mem_store_data,
                mem_dest_reg
            }                        <= 0;
        end else if (hazard_control[`HAZD_HOLD_BIT]) 
            mem_pc_4             <= mem_pc_4; // prevent auto latches
        else begin
            mem_pc_4             <= ex_pc_4;

            mem_reg_write_enable <= ex_reg_write_enable;
            mem_mem_control      <= ex_mem_control;

            mem_alu_result       <= ex_alu_result;
            mem_dest_reg         <= ex_dest_reg;

            case (store_data_select)
                `FORW_SEL_INPUT:    mem_store_data <= ex_store_data;
                `FORW_SEL_ALU_RES:  mem_store_data <= mem_alu_result_prev;
                `FORW_SEL_MEM_RES:  mem_store_data <= wb_reg_write_data;
                default:            mem_store_data <= 0;
            endcase
        end
        
        mem_no_op <= hazard_control[`HAZD_NO_OP_BIT] | ex_no_op;
    end
    
endmodule