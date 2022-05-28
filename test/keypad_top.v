`timescale 1ns / 1ps

module keypad_top (
    input clk, rst_n,
    input [3:0] row_in,
    output [3:0] col_out,
    output [7:0] key_coord
);

keypad_unit_develop keypad(
    .clk(clk),
    .rst_n(rst_n),
    .row_in(row_in),
    .col_out(col_out),
    .key_coord(key_coord)
);

endmodule