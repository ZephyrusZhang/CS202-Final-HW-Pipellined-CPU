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
    
    reg []
    reg [2:0] display_counter;
    reg [3:0] diaplay_digit;
    
    always @(*) begin
        if (~rst_n) begin
            display_counter = 3'b0;
            diaplay_digit = 4'b0;
            has_zero = 1'b0;
            seg_enable = 8'b1111_1111;
        end else begin
            display_counter = display_counter + 1;
            case (display_counter)
                3'd0: begin 
                    diaplay_digit = left_value / 1000;
                    if (diaplay_digit == 0) begin
                        seg_enable = 8'b1111_1111;
                        has_zero = 1'b1;
                    end else seg_enable = 8'b0111_1111;
                end
                3'd1: begin
                    diaplay_digit = (left_value % 1000) / 100;
                    if (has_zero && diaplay_digit == 0) seg_enable = 8'b1111_1111;
                    else begin
                        seg_enable = 8'b1011_1111;
                        has_zero = 1'b0;
                    end
                end
                3'd2: begin
                    diaplay_digit = ((left_value % 1000) % 100) / 10;
                    if (has_zero && diaplay_digit == 0) seg_enable = 8'b1111_1111;
                    else begin
                        seg_enable = 8'b1101_1111;
                        has_zero = 1'b0;
                    end
                end
                3'd3: begin
                    diaplay_digit = ((left_value % 1000) % 100) % 10;
                    if (has_zero && diaplay_digit == 0) seg_enable = 8'b1111_1111;
                    else seg_enable = 8'b1110_1111;
                end
                3'd4: begin
                    diaplay_digit = right_value / 1000;
                    if (diaplay_digit == 0) begin
                        seg_enable = 8'b1111_1111;
                        has_zero = 1'b1;
                    end else seg_enable = 8'b1111_0111;
                end
                3'd5: begin
                    diaplay_digit = (right_value % 1000) / 100;
                    if (has_zero && diaplay_digit == 0) seg_enable = 8'b1111_1111;
                    else begin
                        seg_enable = 8'b1111_1011;
                        has_zero = 1'b0;
                    end
                end
                3'd6: begin
                    diaplay_digit = ((right_value % 1000) % 100) / 10;
                    if (has_zero && diaplay_digit == 0) seg_enable = 8'b1111_1111;
                    else begin
                        seg_enable = 8'b1111_1101;
                        has_zero = 1'b0;
                    end
                end
                3'd7: begin
                    diaplay_digit = ((right_value % 1000) % 100) % 10;
                    if (has_zero && diaplay_digit == 0) seg_enable = 8'b1111_1111;
                    else seg_enable = 8'b1111_1110;
                end
                default: seg_enable = 8'b1111_1111;
            endcase
        end
    end
endmodule