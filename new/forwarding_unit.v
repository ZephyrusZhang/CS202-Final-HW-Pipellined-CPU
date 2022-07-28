`include "definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        ex_reg_1_idx, ex_reg_2_idx, ex_reg_dest_idx:
        mem_reg_dest_idx, wb_reg_dest_idx:
        mem_wb_en: write back enable signal in MEM stage (write back enable signal of last instruction)

*/
module forwarding_unit (
    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_1_idx, 
    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_2_idx,
    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx,

    input      mem_wb_en,
    input      mem_no_op,
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_reg_dest_idx,

    input      wb_wb_en,
    input      wb_no_op,
    input      [`REG_FILE_ADDR_WIDTH - 1:0] wb_reg_dest_idx,

    output reg [`FORW_SEL_WIDTH - 1:0] operand_1_select,
    output reg [`FORW_SEL_WIDTH - 1:0] operand_2_select,
    output reg [`FORW_SEL_WIDTH - 1:0] store_data_select
    );

    wire mem_valid = ~mem_no_op & mem_wb_en & (mem_reg_dest_idx != 0);
    wire wb_valid  = ~wb_no_op  & wb_wb_en  & (wb_reg_dest_idx  != 0);

    always @(*) begin
        casex ({
                   mem_valid & (ex_reg_dest_idx == mem_reg_dest_idx), 
                   wb_valid  & (ex_reg_dest_idx == wb_reg_dest_idx )
               })
            2'b1x  : store_data_select <= `FORW_SEL_ALU_RES;
            2'b01  : store_data_select <= `FORW_SEL_MEM_RES;
            default: store_data_select <= `FORW_SEL_INPUT;
        endcase
    end
    always @(*) begin
        casex ({
                   mem_valid & (ex_reg_1_idx == mem_reg_dest_idx),
                   wb_valid  & (ex_reg_1_idx == wb_reg_dest_idx )
               })
            2'b1x  : operand_1_select  <= `FORW_SEL_ALU_RES;
            2'b01  : operand_1_select  <= `FORW_SEL_MEM_RES;
            default: operand_1_select  <= `FORW_SEL_INPUT;
        endcase
    end
    always @(*) begin
        casex ({
                   mem_valid & (ex_reg_2_idx == mem_reg_dest_idx),
                   wb_valid  & (ex_reg_2_idx == wb_reg_dest_idx )
               })
            2'b1x  : operand_2_select  <= `FORW_SEL_ALU_RES;
            2'b01  : operand_2_select  <= `FORW_SEL_MEM_RES;
            default: operand_2_select  <= `FORW_SEL_INPUT;
        endcase
    end
endmodule