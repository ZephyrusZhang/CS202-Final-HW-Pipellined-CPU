`timescale 1ns / 1ps
`include "../definitions.v"

module seven_seg_unit (
    input clk_tube, rst_n,                          
    input      tube_enable,                                             // from hazard_unit (show the user input on tubes)

    input      [`DIGIT_CNT * `DIGIT_RADIX_WIDTH - 1:0] keypad_digits,   // from input_unit (digits to be displayed during user input)
    input      switch_enable,                                           // from input_unit (show binary switch input)
    input      [`SWITCH_CNT - 1:0] switch_map,                          // from toggle switches hardware directly
    
    output reg [`SEGMENT_CNT - 1:0] seg_tube,                           // control signal for tube segments
    output reg [`DIGIT_CNT - 1:0] seg_enable                            // control signal for digits on the segment display
    );
    
    reg [`DIGIT_CNT_WIDTH - 1:0] display_counter;
    reg [`DIGIT_RADIX_WIDTH - 1:0] display_digit;
    reg has_zero;
    
    always @(posedge clk_tube, negedge rst_n) begin
        if (~rst_n) begin
            {
                display_counter,
                display_digit
            }          = 0;
            has_zero   = 1'b0;
            seg_enable = `DISABLE_ALL_DIGITS;
        end else case ({tube_enable, switch_enable})
            2'b11  : begin
                display_digit   = switch_map[(display_counter)+:1];

                seg_enable                       = `DISABLE_ALL_DIGITS;
                seg_enable[(display_counter)+:1] = 1'b0;

                display_counter = display_counter + 1;
            end
            2'b10  : begin
                display_digit   = keypad_digits[(display_counter * `DIGIT_RADIX_WIDTH)+:`DIGIT_RADIX_WIDTH];

                has_zero        = (display_digit == 0 & (display_counter == 0 | has_zero));

                seg_enable                       = `DISABLE_ALL_DIGITS;
                seg_enable[(display_counter)+:1] = has_zero;

                display_counter = display_counter + 1;
            end
            /* display is not enabled */
            default: 
                seg_enable = `DISABLE_ALL_DIGITS;
        endcase
    end
    
    always @(*)
         case (display_digit)
             4'h0:    seg_tube = 8'b11000000; // "0"
             4'h1:    seg_tube = 8'b11111001; // "1"
             4'h2:    seg_tube = 8'b10100100; // "2"
             4'h3:    seg_tube = 8'b10110000; // "3"
             4'h4:    seg_tube = 8'b10011001; // "4"
             4'h5:    seg_tube = 8'b10010010; // "5"
             4'h6:    seg_tube = 8'b10000010; // "6"
             4'h7:    seg_tube = 8'b11111000; // "7"
             4'h8:    seg_tube = 8'b10000000; // "8"
             4'h9:    seg_tube = 8'b10010000; // "9"
             default: seg_tube = 8'b00000000; // empty
         endcase  
endmodule
