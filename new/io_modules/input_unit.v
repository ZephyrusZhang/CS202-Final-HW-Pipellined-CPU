`include "../definitions.v"
`timescale 1ns / 1ps

module input_unit (
    input clk, rst_n,
    
    input      [7:0] key_coord,                         // from keypad_decoder with format {row_val, col_val}
    input      [`SWITCH_CNT - 1:0] switch_map,          // from toggle switches directly

    input      uart_complete,                           // from uart_unit (upg_done_i)

    input      input_enable,                            // from data_mem (the keypad input will be memory data)
    output reg input_complete,                          // for hazard_unit (user pressed enter)
    output     [`ISA_WIDTH - 1:0] input_data,           // for data_mem (data from user input)
    
    output reg switch_enable,                           // for (1) seven_seg_unit (user is using switches)
                                                        //     (2) output_unit (display that input is switches)
    output reg cpu_pause,                               // for hazard_unit (user pressed pause)

    output reg [1:0] input_state
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
    
    // reg [1:0] input_state;
    reg [2:0] digit_counter, keypad_digit;
    reg [`SWITCH_CNT - 1:0] switch_data;
    reg [`ISA_WIDTH - 1:0] keypad_data;

    assign input_data = switch_enable ? {{(`ISA_WIDTH - `SWITCH_CNT){1'b0}}, switch_data} : keypad_data;

    always @(posedge clk, negedge rst_n) begin // posedge is chosen to reterive results from keypad (negedge)
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
                        TOGGLE : begin
                            input_state    <= KEYPAD;
                            switch_enable  <= 1'b0;
                            switch_data    <= 0;
                        end
                        ENTER  : begin
                            input_state    <= BLOCK;
                            input_complete <= 1'b1;
                            digit_counter  <= 0;
                        end
                        PAUSE  : begin
                            input_state    <= HALT;
                            input_complete <= 1'b1;
                            digit_counter  <= 0;
                            cpu_pause      <= 1'b1;
                        end
                        default:
                            switch_data    <= switch_map;
                    endcase
                end
                KEYPAD : begin
                    if (input_enable == 1'b1) begin 
                        case (key_coord)
                            TOGGLE   : begin
                                input_state    <= SWITCH;
                                switch_enable  <= 1'b1;
                                switch_data    <= 0;
                            end
                            BACKSPACE: begin
                                if (digit_counter != 0)
                                    keypad_data <= keypad_data / 10;
                                else
                                    keypad_data <= keypad_data;
                            end
                            ENTER    : begin
                                input_state    <= BLOCK;
                                input_complete <= 1'b1;
                                digit_counter  <= 0;
                            end
                            PAUSE  : begin
                                input_state    <= HALT;
                                input_complete <= 1'b1;
                                digit_counter  <= 0;
                                cpu_pause      <= 1'b1;
                            end
                            default  : begin
                                if (digit_counter != 8) begin
                                    case (key_coord)
                                        ZERO   : keypad_data <= keypad_data * 10;
                                        ONE    : keypad_data <= keypad_data * 10 + 1;
                                        TWO    : keypad_data <= keypad_data * 10 + 2;
                                        THREE  : keypad_data <= keypad_data * 10 + 3;
                                        FOUR   : keypad_data <= keypad_data * 10 + 4;
                                        FIVE   : keypad_data <= keypad_data * 10 + 5;
                                        SIX    : keypad_data <= keypad_data * 10 + 6;
                                        SEVEN  : keypad_data <= keypad_data * 10 + 7;
                                        EIGHT  : keypad_data <= keypad_data * 10 + 8;
                                        NINE   : keypad_data <= keypad_data * 10 + 9;
                                        default: keypad_data <= keypad_data;  // 0 key_coord will be handled here
                                    endcase
                                    digit_counter <= digit_counter + 1;
                                end else
                                    keypad_data    <= keypad_data;
                            end
                        endcase
                    end else
                        input_state        <= BLOCK;
                end
                HALT   : begin
                    if (uart_complete & key_coord == PAUSE) begin
                        input_state        <= BLOCK;
                        cpu_pause          <= 1'b0;
                    end else
                        cpu_pause          <= 1'b1;
                end
                // this is the BLOCK state
                default: begin
                    casex ({key_coord == PAUSE, input_enable})
                        2'b1x  : begin
                            input_state    <= HALT;
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