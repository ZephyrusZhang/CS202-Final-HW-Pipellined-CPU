`include "../definitions.v"
`timescale 1ns / 1ps

module keypad_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                         // from keypad_decoder with format {row_val, col_val}

    input      keypad_read_enable,                      // from data_mem (the keypad input will be memory data)
    output reg [`ISA_WIDTH - 1:0] keypad_read_data,     // for data_mem (data from user input)
    output reg 
    );

endmodule