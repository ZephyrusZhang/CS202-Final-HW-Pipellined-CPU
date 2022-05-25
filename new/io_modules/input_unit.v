`include "../definitions.v"
`timescale 1ns / 1ps

module input_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                         // from keypad_decoder with format {row_val, col_val}
    input      [`SWITCH_CNT - 1:0] switch_map,          // from toggle switches directly

    input      input_enable,                            // from data_mem (the keypad input will be memory data)
    output reg input_complete,                          // for hazard_unit (user pressed enter)
    output     [`ISA_WIDTH - 1:0] input_data,           // for data_mem (data from user input)
    
    output reg switch_enable,                           // for seven_seg_unit (user is using switches)
    output reg cpu_pause                                // for hazard_unit (user pressed pause)
    );
               
    localparam  ZERO        = ,
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
                PAUSE       = 8'b1110_0111, // "A" : pause and resume cpu execution
                SWITCH      = 8'b1101_0111, // "B" : change input between switches and keypad
                C           = 8'b1011_0111,
                D           = 8'b0111_0111;
    
    localparam  BLOCK       = 2'b00,
                SWITCH      = 2'b01,
                KEYPAD      = 2'b10,
                PAUSE       = 2'b11;
    
    reg [1:0] input_state;
    reg [2:0] digit_counter, keypad_digit;
    reg [`SWITCH_CNT - 1:0] switch_data;
    reg [`ISA_WIDTH - 1:0] keypad_data;

    assign input_data = switch_enable ? {{`ISA_WIDTH - `SWITCH_CNT{1'b0}}, switch_data} : keypad_data;

    always @(key_coord) begin
        case (key_coord)
            ZERO     : keypad_digit <= 3'd0;
            ONE      : keypad_digit <= 3'd1;
            TWO      : keypad_digit <= 3'd2;
            THREE    : keypad_digit <= 3'd3;
            FOUR     : keypad_digit <= 3'd4;
            FIVE     : keypad_digit <= 3'd5;
            SIX      : keypad_digit <= 3'd6;
            SEVEN    : keypad_digit <= 3'd7;
            EIGHT    : keypad_digit <= 3'd8;
            NINE     : keypad_digit <= 3'd9;
            default  : keypad_digit <= 3'd0;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                input_complete,
                keypad_data,
                switch_data,
                switch_enable,
                cpu_pause,
                input_state,
                digit_counter
            } <= 0;
        end else begin
            case (input_state)
                SWITCH : begin
                    case (key_coord)
                        SWITCH : begin
                            switch_enable  <= 1'b0;
                            switch_data    <= 0;
                        end
                        ENTER  : begin
                            input_state    <= BLOCK;
                            input_complete <= 1'b1;
                            digit_counter  <= 0;
                        end
                        default:
                            switch_data    <= switch_map;
                    endcase
                end
                KEYPAD : begin
                    if (input_enable == 1'b1) begin 
                        case (key_coord)
                            BACKSPACE:
                            ENTER    :
                            SWITCH   : 
                            default  : begin
                                case (digit_counter)
                                    3'd0 : begin
                                        input_data <= input_data + 
                                        digit_counter <= digit_counter + 1;
                                    end
                                    3'd1 : begin
                                        
                                    end 
                                    BACKSPACE:
                                    default  : 
                                endcase
                                digit_counter <= digit_counter + 1;
                            end
                        endcase
                    end else
                        input_state        <= BLOCK;
                end
                PAUSE  : begin
                    
                end
                // this is the BLOCK state
                default: begin
                    casex ({key_coord == PAUSE, input_enable})
                        2'b1x  : begin
                            input_state    <= PAUSE;
                            cpu_pause      <= 1'b1;
                        end 
                        2'b01  : begin
                            input_state    <= KEYPAD;
                            input_complete <= 1'b0;
                            input_data     <= 0;
                        end
                        default: 
                            input_state    <= BLOCK;
                    endcase
                end
        end
    end
endmodule