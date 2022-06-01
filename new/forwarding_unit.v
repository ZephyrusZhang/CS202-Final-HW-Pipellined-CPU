`include "definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        src1, src2, st_src:
        dest_mem, dest_wb:
        mem_wb_en: write back enable signal in MEM stage (write back enable signal of last instruction)

*/
module forwarding_unit (
    input [`REG_FILE_ADDR_WIDTH - 1 : 0] src1, src2, st_src,
    input [`REG_FILE_ADDR_WIDTH - 1 : 0] dest_mem, dest_wb,
    input      mem_wb_en, wb_en,
    input      dest_mem_no_op, dest_wb_no_op,
    output reg [`FORW_SEL_WIDTH - 1 : 0] val1_sel, val2_sel, st_sel
);

always @(*) begin
    {val1_sel, val2_sel, st_sel} <= 6'b00_00_00;

    if (~dest_mem_no_op & mem_wb_en & st_src == dest_mem & dest_mem != 5'b00000) st_sel <= `FORW_SEL_ALU_RES;
    else if (~dest_wb_no_op & wb_en & st_src == dest_wb & dest_wb != 5'b00000) st_sel <= `FORW_SEL_MEM_RES;

    if (~dest_mem_no_op & mem_wb_en & src1 == dest_mem & dest_mem != 5'b00000)   val1_sel <= `FORW_SEL_ALU_RES;
    else if (~dest_wb_no_op & wb_en & src1 == dest_wb & dest_wb != 5'b00000)   val1_sel <= `FORW_SEL_MEM_RES;

    if (~dest_mem_no_op & mem_wb_en & src2 == dest_mem & dest_mem != 5'b00000)   val2_sel <= `FORW_SEL_ALU_RES;
    else if (~dest_wb_no_op & wb_en & src2 == dest_wb & dest_wb != 5'b00000)   val2_sel <= `FORW_SEL_MEM_RES;
end

endmodule