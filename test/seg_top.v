`timescale 1ns / 1ps
`include "../new/definitions.v"

module seg_top (
    input clk, rst_n,
    input [`ISA_WIDTH - 1 : 0] display_value,
    output [7 : 0] seg_tube,
    output [7 : 0] seg_enable
);

seven_seg_unit seven_seg(
    .clk(clk),
    .rst_n(rst_n),
    .display_value(32'h80000000),
    .switch_enable(1'b0),
    .input_enable(1'b1),
    .seg_tube(seg_tube),
    .seg_enable(seg_enable)
);

endmodule