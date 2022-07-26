`include "../definitions.v"
`timescale 1ns / 1ps

module input_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                         // from keypad_unit with format {row_val, col_val}

    input      ignore_pause,                            // from hazard_unit (whether user input is ignored during UART transmission)

    input      input_enable,                            // from data_mem (the keypad input will be memory data)
    output reg input_complete,                          // for hazard_unit (user pressed enter)
    output reg [`ISA_WIDTH - 1:0] keypad_data,          // for (1) mem_wb_reg (data from user keypad input)
                                                        //     (2) seven_seg_unit (data to be displayed during user input)
    
    output reg switch_enable,                           // for (1) seven_seg_unit (user is using switches)
                                                        //     (2) output_unit (display that input is switches)
                                                        //     (3) mem_wb_reg (select the appropriate value from switch or keypad)
    output reg cpu_pause,                               // for hazard_unit (user pressed pause)
    output     overflow_9th,                            // for hardware LED to indicate a overflow of the 9th  digit on tube display
    output     overflow_10th                            // for hardware LED to indicate a overflow of the 10th digit on tube display
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
                STATE_SWITCH  = 2'b01,
                STATE_KEYPAD  = 2'b10,
                STATE_PAUSE   = 2'b11;
    
    reg [1:0] input_state, prev_state;
    reg [3:0] digit_counter;

    assign overflow_9th  = (9  <= digit_counter);
    assign overflow_10th = (10 == digit_counter);

    always @(posedge clk, negedge rst_n) begin // posedge is chosen to reterive results from keypad (negedge)
        if (~rst_n) begin
            {
                input_complete,
                keypad_data,
                switch_enable,
                cpu_pause,
                digit_counter
            }           <= 0;
            input_state <= STATE_BLOCK;
            prev_state  <= STATE_BLOCK;
        end else begin
            case (input_state)
                STATE_SWITCH: begin
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
                            prev_state     <= input_state;
                            cpu_pause      <= 1'b1;
                        end
                        default   :
                            input_state    <= input_state; // prevent auto latches
                    endcase
                end
                STATE_KEYPAD: begin
                    case (key_coord)
                        KEY_SWITCH   : begin
                            input_state    <= STATE_SWITCH;
                            switch_enable  <= 1'b1;
                        end
                        KEY_BACKSPACE: begin
                            if (digit_counter != 0) begin
                                keypad_data   <= keypad_data / 10;
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
                            prev_state     <= input_state;
                            cpu_pause      <= 1'b1;
                        end
                        default      : begin
                            if (digit_counter < 10) begin
                                case (key_coord)
                                    KEY_ONE  : begin
                                        keypad_data   <= keypad_data * 10 + 1;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_TWO  : begin
                                        keypad_data   <= keypad_data * 10 + 2;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_THREE: begin
                                        keypad_data   <= keypad_data * 10 + 3;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_FOUR : begin
                                        keypad_data   <= keypad_data * 10 + 4;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_FIVE : begin
                                        keypad_data   <= keypad_data * 10 + 5;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_SIX  : begin
                                        keypad_data   <= keypad_data * 10 + 6;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_SEVEN: begin
                                        keypad_data   <= keypad_data * 10 + 7;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_EIGHT: begin
                                        keypad_data   <= keypad_data * 10 + 8;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_NINE : begin
                                        keypad_data   <= keypad_data * 10 + 9;
                                        digit_counter <= digit_counter + 1;
                                    end
                                    KEY_ZERO :
                                        if (0 < keypad_data) begin
                                            keypad_data   <= keypad_data * 10;
                                            digit_counter <= digit_counter + 1;
                                        end else
                                            input_state   <= input_state; // prevent auto latches
                                    default  : 
                                        input_state   <= input_state; // 0 key_coord will be handled here
                                endcase
                            end else
                                input_state   <= input_state;
                        end
                    endcase
                end
                STATE_PAUSE : begin
                    if (~ignore_pause & key_coord == KEY_PAUSE) begin
                        input_state        <= prev_state;
                        cpu_pause          <= 1'b0;
                    end else
                        cpu_pause          <= cpu_pause; // prevent auto latches
                end
                // this is the STATE_BLOCK state
                default     : begin
                    casex ({key_coord == KEY_PAUSE, input_enable})
                        2'b1x  : begin
                            input_state    <= STATE_PAUSE;
                            prev_state     <= input_state;
                            cpu_pause      <= 1'b1;
                        end 
                        2'b01  : begin
                            input_state    <= STATE_KEYPAD;
                            input_complete <= 1'b0;
                            keypad_data    <= 0;
                        end
                        default: 
                            input_state    <= input_state;
                    endcase
                end
            endcase
        end
    end

endmodule