`include "../definitions.v"
`timescale 1ns / 1ps

module input_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                         // from keypad_decoder with format {row_val, col_val}

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
                PAUSE       = 8'b1110_0111, // "A": pause and resume cpu execution
                TOGGLE      = 8'b1101_0111, // "B": change input between switches and keypad
                C           = 8'b1011_0111,
                D           = 8'b0111_0111;
    
    localparam  BLOCK       = 2'b00,
                SWITCH      = 2'b01,
                KEYPAD      = 2'b10,
                HALT        = 2'b11;
    
    reg [1:0] input_state, prev_state;
    reg [3:0] digit_counter;

    assign overflow_9th  = (9 <= digit_counter);
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
            input_state <= BLOCK;
            prev_state  <= BLOCK;
        end else begin
            case (input_state)
                SWITCH : begin
                    case (key_coord)
                        TOGGLE : begin
                            input_state    <= KEYPAD;
                            switch_enable  <= 1'b0;
                        end
                        ENTER  : begin
                            input_state    <= BLOCK;
                            input_complete <= 1'b1;
                            digit_counter  <= 4'h0;
                        end
                        PAUSE  : begin
                            input_state    <= HALT;
                            prev_state     <= input_state;
                            cpu_pause      <= 1'b1;
                        end
                        default:
                            input_state    <= input_state;
                    endcase
                end
                KEYPAD : begin
                    if (input_enable) begin 
                        case (key_coord)
                            TOGGLE   : begin
                                input_state    <= SWITCH;
                                switch_enable  <= 1'b1;
                            end
                            BACKSPACE: begin
                                if (digit_counter != 0) begin
                                    keypad_data   <= keypad_data / 10;
                                    digit_counter <= digit_counter - 1;
                                end else
                                    keypad_data   <= keypad_data;
                            end
                            ENTER    : begin
                                input_state    <= BLOCK;
                                input_complete <= 1'b1;
                                digit_counter  <= 4'h0;
                            end
                            PAUSE  : begin
                                input_state    <= HALT;
                                prev_state     <= input_state;
                                cpu_pause      <= 1'b1;
                            end
                            default  : begin
                                if (digit_counter < 10) begin
                                    case (key_coord)
                                        ONE    : begin
                                            keypad_data   <= keypad_data * 10 + 1;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        TWO    : begin
                                            keypad_data   <= keypad_data * 10 + 2;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        THREE  : begin
                                            keypad_data   <= keypad_data * 10 + 3;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        FOUR   : begin
                                            keypad_data   <= keypad_data * 10 + 4;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        FIVE   : begin
                                            keypad_data   <= keypad_data * 10 + 5;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        SIX    : begin
                                            keypad_data   <= keypad_data * 10 + 6;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        SEVEN  : begin
                                            keypad_data   <= keypad_data * 10 + 7;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        EIGHT  : begin
                                            keypad_data   <= keypad_data * 10 + 8;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        NINE   : begin
                                            keypad_data   <= keypad_data * 10 + 9;
                                            digit_counter <= digit_counter + 1;
                                        end
                                        ZERO   : begin
                                            keypad_data   <= keypad_data * 10;
                                            if (0 < keypad_data) digit_counter <= digit_counter + 1;
                                        end
                                        default: 
                                            keypad_data <= keypad_data; // 0 key_coord will be handled here
                                    endcase
                                end else
                                    keypad_data <= keypad_data;
                            end
                        endcase
                    end else
                        input_state        <= BLOCK;
                end
                HALT   : begin
                    if (~ignore_pause & key_coord == PAUSE) begin
                        input_state        <= prev_state;
                        cpu_pause          <= 1'b0;
                    end else
                        cpu_pause          <= cpu_pause; // prevent auto latches
                end
                // this is the BLOCK state
                default: begin
                    casex ({key_coord == PAUSE, input_enable})
                        2'b1x  : begin
                            input_state    <= HALT;
                            prev_state     <= input_state;
                            cpu_pause      <= 1'b1;
                        end 
                        2'b01  : begin
                            input_state    <= KEYPAD;
                            input_complete <= 1'b0;
                            keypad_data    <= 0;
                        end
                        default: 
                            input_state    <= BLOCK;
                    endcase
                end
            endcase
        end
    end

endmodule