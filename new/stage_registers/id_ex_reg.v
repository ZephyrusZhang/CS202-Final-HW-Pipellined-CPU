`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction decoding (id) stage
    execution (ex) stage
 */

module id_ex_reg (
    input clk, rst_n,

    input      [1:0] hazard_control,                            // from hazard_unit [HAZD_HOLD_BIT] discard id result
                                                                //                  [HAZD_NO_OP_BIT] pause ex stage
    input      id_no_op,                                        // from if_id_reg (the operations of id have been stoped)
    output reg ex_no_op,                                        // for alu (stop opeartions)

    input      id_reg_write_enable,                             // from control_unit (instruction needs write to register)
    output reg ex_reg_write_enable,                             // for ex_mem_reg

    input      [1:0] id_mem_control,                            // from control_unit ([0] write, [1] read)
    output reg [1:0] ex_mem_control,                            // for ex_mem_reg

    input      [`ALU_CONTROL_WIDTH - 1:0] id_alu_control,       // from control_unit (alu control signals)
    output reg [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control,       // for alu

    input      [`ISA_WIDTH - 1:0] mux_operand_1,                // from signal_mux (first operand for alu)
    output reg [`ISA_WIDTH - 1:0] ex_operand_1,                 // for alu (first oprand for alu)

    input      [`ISA_WIDTH - 1:0] mux_operand_2,                // from signal_mux (second operand for alu)
    output reg [`ISA_WIDTH - 1:0] ex_operand_2,                 // for alu (second oprand for alu)

    input      [`ISA_WIDTH - 1:0] id_reg_2,                     // from general_reg (second register's value)
    output reg [`ISA_WIDTH - 1:0] ex_store_data,                // for ex_mem_reg (the data to be store into memory)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx,      // from signal_mux (index of first source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx,      // from signal_mux (index of second source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx,   // from signal_mux (index of destination resgiter)
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_1_idx,       // for forwarding_unit
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_2_idx,       // for forwarding_unit
    output reg [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx     // for (1) forwarding_unit
                                                                //     (2) hazrad_unit
                                                                //     (3) ex_mem_reg
    );

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                ex_no_op,

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
        end else if (hazard_control[`HAZD_HOLD_BIT])
            ex_reg_write_enable <= ex_reg_write_enable;     // prevent auto latches
        else begin
            ex_reg_write_enable <= id_reg_write_enable;
            ex_mem_control      <= id_mem_control;
            ex_alu_control      <= id_alu_control;
            
            ex_operand_1        <= mux_operand_1;
            ex_operand_2        <= mux_operand_2;

            ex_store_data       <= id_reg_2;

            ex_reg_1_idx        <= mux_reg_1_idx;
            ex_reg_2_idx        <= mux_reg_2_idx;
            ex_reg_dest_idx     <= mux_reg_dest_idx;
        end

        ex_no_op <= hazard_control[`HAZD_NO_OP_BIT] | id_no_op;
    end
    
endmodule