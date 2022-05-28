`timescale 1ns / 1ps
`include "../new/definitions.v"

module seg_top (
    input clk, rst_n, switch_en,
    output [6 : 0] seg_tube,
    output [7 : 0] seg_enable
);

seven_seg_unit seven_seg (
    .clk(clk),
    .rst_n(rst_n),
    .display_value(32'h00114514),
    .switch_enable(switch_en),
    .input_enable(1'b1),
    .seg_tube(seg_tube),
    .seg_enable(seg_enable)
);

endmodule