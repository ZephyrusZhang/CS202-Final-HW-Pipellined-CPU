`timescale 1ns / 1ps
`include "../../new/definitions.v"

module input_top (
    input clk, rst_n,
    input [3:0] row_in,
    input [`SWITCH_CNT - 1 : 0] switch_map,
    output [3:0] col_out,
    output [6:0] seg_tube,
    output [7:0] seg_enable,
    output input_complete_led,
    output cpu_pause_led,
    output [1:0] input_state,
    output overflow,
    output [3:0] counter
);

wire [7:0] key_coord;
wire input_complete;
wire [`ISA_WIDTH - 1 : 0] output_data;
wire switch_enable;

keypad_unit keypad (
    .clk(clk),
    .rst_n(rst_n),
    .row_in(row_in),
    .col_out(col_out),
    .key_coord(key_coord)
);

input_unit input_test (
    .clk(clk),
    .rst_n(rst_n),
    .key_coord(key_coord),
    .switch_map(switch_map),
    .uart_complete(1'b1),
    .input_enable(1'b1),
    .input_complete(input_complete_led),
    .input_data(output_data),
    .switch_enable(switch_enable),
    .cpu_pause(cpu_pause_led),
    .overflow(overflow),
    .counter(counter)
);

seven_seg_unit seg(
    .clk(clk),
    .rst_n(rst_n),
    .display_value(output_data),
    .switch_enable(switch_enable),
    .input_enable(1'b1),
    .seg_tube(seg_tube),
    .seg_enable(seg_enable)
);
    
endmodule