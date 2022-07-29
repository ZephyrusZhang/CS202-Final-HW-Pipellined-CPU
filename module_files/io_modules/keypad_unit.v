`timescale 1ns / 1ps
`include "../definitions.v"

module keypad_unit (
    input wire clk, rst_n,
    
    input wire [3:0] row_in,
    output reg [3:0] col_out,
    
    output reg [7:0] key_coord
    );
    
    localparam  SCAN_COL_1    = 2'b00,
                SCAN_COL_2    = 2'b01,
                SCAN_COL_3    = 2'b10,
                SCAN_COL_4    = 2'b11,
                DISABLE_COL_1 = 4'b0111,
                DISABLE_COL_2 = 4'b1011,
                DISABLE_COL_3 = 4'b1101,
                DISABLE_COL_4 = 4'b1110;

    localparam  TRAVERSE_PERIOD = 10, // time given for the signal to travel to the keypad
                COLUMN_PERIOD   = `KEYPAD_DELAY_PERIOD / 4;
    
    reg [1:0]  state;
    reg [20:0] delay_duration;
    reg [3:0]  row_pre [3:0];
    reg [3:0]  row_old [3:0];
    
    integer i;
    always @(negedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                delay_duration,
                key_coord
            }       = 0;

            state   = SCAN_COL_1;
            col_out = DISABLE_COL_1;

            for (i = 0; i < 4; i = i + 1) begin
                row_pre[i] = 4'hf;
                row_old[i] = 4'hf;
            end
        end else case ({delay_duration == TRAVERSE_PERIOD, // check for changes by the scanning signal
                        delay_duration == COLUMN_PERIOD})  // let out the next signal for scanning
            2'b10  : begin
                delay_duration = delay_duration + 1;

                if (row_in         != 4'hf &  // currently key is being pressed
                    row_old[state] == 4'hf &  // two periods ago no key is pressed
                    row_pre[state] == row_in) // one preiod ago the same key is pressed

                    key_coord  = {col_out, row_in};
                else 
                    key_coord  = 0;
                
                row_old[state] = row_pre[state];
                row_pre[state] = row_in;
                state          = state + 1;
            end
            2'b01  : begin
                delay_duration = 0;

                case (state)
                    SCAN_COL_1: col_out = DISABLE_COL_1;
                    SCAN_COL_2: col_out = DISABLE_COL_2;
                    SCAN_COL_3: col_out = DISABLE_COL_3;
                    default   : col_out = DISABLE_COL_4; // SCAN_COL_4
                endcase
            end
            default: begin
                delay_duration = delay_duration + 1;
                key_coord      = 0;
            end
        endcase
    end
endmodule