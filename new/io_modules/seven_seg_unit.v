`timescale 1ns / 1ps
`include "../definitions.v"

module seven_seg_unit (
    input clk_tube, rst_n,                          
    input      [`ISA_WIDTH - 1:0] keypad_data,      // from keypad_unit (data from user keypad input)
    input      [`SWITCH_CNT - 1:0] switch_map,      // from toggle switches hardware directly
    input      switch_enable,                       // from keypad_unit (show binary switch input)
    input      input_enable,                        // from data_mem (the keypad input is needed)
    
    output reg [`SEGMENT_CNT - 1:0] seg_tube,       // control signal for tube segments
    output reg [`DIGIT_CNT - 1:0] seg_enable        // control signal for digits on the segment display
    );
    
    reg [`DIGIT_CNT_WIDTH - 1:0] display_counter;
    reg [`DIGIT_RADIX_WIDTH - 1:0] diaplay_digit;
    reg has_zero;
    
    always @(posedge clk_tube, negedge rst_n) begin
        if (~rst_n) begin
            {
                display_counter,
                diaplay_digit
            }           = 0;
            has_zero    = 1'b0;
            seg_enable  = `DISABLE_ALL_DIGITS;
        end else case ({input_enable, switch_enable})
            2'b11  : begin
                diaplay_digit = switch_map[(display_counter)+:1];
                seg_enable = `DISABLE_ALL_DIGITS;
                seg_enable[(display_counter)+:1] = 1'b0;
                display_counter = display_counter + 1;
            end
            2'b10  : begin
                case (display_counter)
                    3'd0: begin 
                        diaplay_digit = (keypad_data % `DIGIT_1_MOD) / `DIGHT_2_MOD;

                        if (diaplay_digit == 0) begin
                            seg_enable = `DISABLE_ALL_DIGITS;
                            has_zero   = 1'b1;
                        end else 
                            seg_enable = `ENABLE_DIGHT_1;
                    end
                    3'd1: begin
                        diaplay_digit = (keypad_data % `DIGHT_2_MOD) / `DIGHT_3_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_2;
                            has_zero   = 1'b0;
                        end
                    end
                    3'd2: begin
                        diaplay_digit = (keypad_data % `DIGHT_3_MOD) / `DIGHT_4_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_3;
                            has_zero   = 1'b0;
                        end
                    end
                    3'd3: begin
                        diaplay_digit = (keypad_data % `DIGHT_4_MOD) / `DIGHT_5_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_4;
                            has_zero   = 1'b0;
                        end
                    end
                    3'd4: begin
                        diaplay_digit = (keypad_data % `DIGHT_5_MOD) / `DIGHT_6_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_5;
                            has_zero   = 1'b0;
                        end
                    end
                    3'd5: begin
                        diaplay_digit = (keypad_data % `DIGHT_6_MOD) / `DIGHT_7_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_6;
                            has_zero   = 1'b0;
                        end
                    end
                    3'd6: begin
                        diaplay_digit = (keypad_data % `DIGHT_7_MOD) / `DIGHT_8_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_7;
                            has_zero   = 1'b0;
                        end
                    end
                    3'd7: begin
                        diaplay_digit = (keypad_data % `DIGHT_8_MOD) / `DIGHT_9_MOD;

                        if (has_zero & (diaplay_digit == 0)) 
                            seg_enable = `DISABLE_ALL_DIGITS;
                        else begin
                            seg_enable = `ENABLE_DIGHT_8;
                            has_zero   = 1'b0;
                        end
                    end
                    default: 
                        seg_enable = `DISABLE_ALL_DIGITS;
                endcase
                display_counter = display_counter + 1;
            end
            // display is not enabled
            default: 
                seg_enable = `DISABLE_ALL_DIGITS;
        endcase
    end
    
    always @(*)
         case (diaplay_digit)
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
