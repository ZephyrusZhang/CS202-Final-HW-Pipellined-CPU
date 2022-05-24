`include "../definitions.v"
`timescale 1ns / 1ps

module keypad_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                         // from keypad_decoder with format {row_val, col_val}

    input      keypad_read_enable,                      // from data_mem (the keypad input will be memory data)
    output reg keypad_read_complete,
    output reg [`ISA_WIDTH - 1:0] keypad_read_data,     // for data_mem (data from user input)
    
    output reg cpu_pause,
    output reg cpu_resume
    );
               
    localparam  ZERO        = 8'b0111_1101,
                ONE         = 8'b1110_1110,
                TWO         = 8'b1110_1101,
                THREE       = 8'b1110_1011,
                FOUR        = 8'b1101_1110,
                FIVE        = 8'b1101_1101,
                SIX         = 8'b1101_1011,
                SEVEN       = 8'b1011_1110,
                EIGHT       = 8'b1011_1101,
                NINE        = 8'b1011_1011,
                BACKSPACE   = 8'b0111_1110, // "*": deletes the last digit
                ENTER       = 8'b0111_1011, // "#": comfirmes the input with leading zeros
                A           = 8'b1110_0111, // pause and resume cpu execution
                B           = 8'b1101_0111,
                C           = 8'b1011_0111,
                D           = 8'b0111_0111;
    
    
endmodule