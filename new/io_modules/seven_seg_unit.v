`timescale 1ns / 1ps

module seven_seg_unit (
    input      clk_tube, rst_n,             // note this is a clock for tube 1ms refresh
    input      [26:0] display_value,        // from keypad_unit (value to be displayed)
    
    output reg [6:0] seg_tube,              // control signal for tube segments
    output reg [7:0] seg_enable             // control signal for tube positions
    );
    
    reg [2:0] display_counter;
    reg [3:0] diaplay_digit;
    reg has_zero;
    
    always @(posedge clk_tube, negedge rst_n) begin
        if (!rst_n) begin
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
    
    always @(diaplay_digit)
         case (diaplay_digit)
             4'h0:    seg_tube = 8'b01000000; // "0"
             4'h1:    seg_tube = 8'b01111001; // "1"
             4'h2:    seg_tube = 8'b00100100; // "2"
             4'h3:    seg_tube = 8'b00110000; // "3"
             4'h4:    seg_tube = 8'b00011001; // "4"
             4'h5:    seg_tube = 8'b00010010; // "5"
             4'h6:    seg_tube = 8'b00000010; // "6"
             4'h7:    seg_tube = 8'b01111000; // "7"
             4'h8:    seg_tube = 8'b00000000; // "8"
             4'h9:    seg_tube = 8'b00010000; // "9"
             default: seg_tube = 8'b00000000; // "0"
         endcase  
endmodule
