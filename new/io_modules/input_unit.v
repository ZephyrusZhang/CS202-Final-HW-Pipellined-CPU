`include "../definitions.v"
`timescale 1ns / 1ps
`define KEYPAD_DIGITS_WIDTH (`DIGIT_CNT + `OVERFLOW_CNT) * `DIGIT_RADIX_WIDTH

module input_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                             // from keypad_unit with format {row_val, col_val}

    input      ignore_pause,                                // from hazard_unit (whether user input is ignored during UART transmission)

    input      input_enable,                                // from data_mem (the keypad input will be memory data)
    output reg input_complete,                              // for hazard_unit (user pressed enter)
    output reg [`ISA_WIDTH - 1:0] keypad_data,              // for mem_wb_reg (data from user keypad input)
    output reg [`KEYPAD_DIGITS_WIDTH - 1:0] keypad_digits,  // for seven_seg_unit (digits to be displayed during user input)

    output reg switch_enable,                               // for (1) seven_seg_unit (user is using switches)
                                                            //     (2) output_unit (display that input is switches)
                                                            //     (3) mem_wb_reg (select the appropriate value from switch or keypad)
    output reg cpu_pause,                                   // for hazard_unit (user pressed pause)
    output     overflow_9th,                                // for hardware LED to indicate a overflow of the 9th  digit on tube display
    output     overflow_10th                                // for hardware LED to indicate a overflow of the 10th digit on tube display
    );
               
    localparam  KEY_ZERO      = 8'b0111_1101,
                KEY_ONE       = 8'b1110_1110,
                KEY_TWO       = 8'b1110_1101,
                KEY_THREE     = 8'b1110_1011,
                KEY_FOUR      = 8'b1101_1110,
                KEY_FIVE      = 8'b1101_1101,
                KEY_SIX       = 8'b1101_1011,
                KEY_SEVEN     = 8'b1011_1110,
                KEY_EIGHT     = 8'b1011_1101,
                KEY_NINE      = 8'b1011_1011,
                KEY_BACKSPACE = 8'b0111_1110, // "*": deletes the last digit
                KEY_ENTER     = 8'b0111_1011, // "#": comfirmes the input with leading zeros
                KEY_PAUSE     = 8'b1110_0111, // "A": pause and resume cpu execution
                KEY_SWITCH    = 8'b1101_0111, // "B": change input between switches and keypad
                KEY_C         = 8'b1011_0111,
                KEY_D         = 8'b0111_0111;
    
    localparam  STATE_BLOCK   = 2'b00,
                STATE_KEYPAD  = 2'b01,
                STATE_SWITCH  = 2'b10,
                STATE_PAUSE   = 2'b11;
    
    reg [1:0] input_state, prev_state;
    reg [`DIGIT_TOTAL_WIDTH - 1:0] digit_counter;
    reg [`DIGIT_RADIX_WIDTH - 1:0] digit_value;

    assign overflow_9th  = ((`DIGIT_CNT + `OVERFLOW_CNT - 1) <= digit_counter);
    assign overflow_10th = ((`DIGIT_CNT + `OVERFLOW_CNT)     == digit_counter);

    always @(*) begin
        case (key_coord)
            KEY_ZERO : digit_value <= 0;
            KEY_ONE  : digit_value <= 1;
            KEY_TWO  : digit_value <= 2;
            KEY_THREE: digit_value <= 3;
            KEY_FOUR : digit_value <= 4;
            KEY_FIVE : digit_value <= 5;
            KEY_SIX  : digit_value <= 6;
            KEY_SEVEN: digit_value <= 7;
            KEY_EIGHT: digit_value <= 8;
            KEY_NINE : digit_value <= 9;
            default  : digit_value <= digit_value;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin // posedge is chosen to reterive results from keypad (negedge)
        if (~rst_n) begin
            {
                input_complete,
                keypad_data,
                keypad_digits,
                digit_value,
                switch_enable,
                cpu_pause,
                digit_counter
            }           <= 0;
            input_state <= STATE_BLOCK;
            prev_state  <= STATE_BLOCK;
        end else begin
            case (input_state)
                STATE_BLOCK : 
                    casex ({input_enable, key_coord == KEY_PAUSE})
                        2'b1x  : begin
                            input_state    <= STATE_KEYPAD;
                            input_complete <= 1'b0;
                            keypad_data    <= 0;
                            keypad_digits  <= 0;
                        end 
                        2'b01  : begin
                            input_state    <= STATE_PAUSE;
                            prev_state     <= STATE_BLOCK;
                            cpu_pause      <= 1'b1;
                        end
                        default: 
                            input_state    <= input_state;
                    endcase
                STATE_KEYPAD: 
                    case (key_coord)
                        KEY_SWITCH   : begin
                            input_state    <= STATE_SWITCH;
                            switch_enable  <= 1'b1;
                        end
                        KEY_BACKSPACE: begin
                            if (digit_counter != 0) begin
                                keypad_data   <= keypad_data / 10;
                                keypad_digits <= {
                                                     keypad_digits[`KEYPAD_DIGITS_WIDTH - 1:`DIGIT_RADIX_WIDTH - 1],
                                                     {`DIGIT_RADIX_WIDTH{1'b0}}
                                                 };
                                digit_counter <= digit_counter - 1;
                            end else
                                input_state   <= input_state; // prevent auto latches
                        end
                        KEY_ENTER    : begin
                            input_state    <= STATE_BLOCK;
                            input_complete <= 1'b1;
                            digit_counter  <= 4'h0;
                        end
                        KEY_PAUSE    : begin
                            input_state    <= STATE_PAUSE;
                            prev_state     <= STATE_KEYPAD;
                            cpu_pause      <= 1'b1;
                        end
                        default      : begin
                            if (key_coord     != 0                            &
                                digit_counter != (`DIGIT_CNT + `OVERFLOW_CNT) & 
                                (digit_value  != 0 | digit_counter != 0))

                                keypad_data   <= keypad_data * 10 + digit_value;
                                keypad_digits <= {
                                                     digit_value,
                                                     keypad_digits[`KEYPAD_DIGITS_WIDTH - 1:`DIGIT_RADIX_WIDTH - 1]
                                                 };
                                digit_counter <= digit_counter + 1;
                            else
                                input_state   <= input_state; // 0 key_coord will be handled here
                        end
                    endcase
                STATE_SWITCH: 
                    case (key_coord)
                        KEY_SWITCH: begin
                            input_state    <= STATE_KEYPAD;
                            switch_enable  <= 1'b0;
                        end
                        KEY_ENTER : begin
                            input_state    <= STATE_BLOCK;
                            input_complete <= 1'b1;
                            digit_counter  <= 4'h0;
                        end
                        KEY_PAUSE : begin
                            input_state    <= STATE_PAUSE;
                            prev_state     <= STATE_SWITCH;
                            cpu_pause      <= 1'b1;
                        end
                        default   :
                            input_state    <= input_state; // prevent auto latches
                    endcase
                /* STATE_PAUSE */
                default     : 
                    if (~ignore_pause & key_coord == KEY_PAUSE) begin
                        input_state        <= prev_state;
                        cpu_pause          <= 1'b0;
                    end else
                        cpu_pause          <= cpu_pause; // prevent auto latches
            endcase
        end
    end

endmodule