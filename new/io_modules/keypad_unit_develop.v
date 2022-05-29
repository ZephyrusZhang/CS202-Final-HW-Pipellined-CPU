`timescale 1ns / 1ps
`define KEYPAD_DEFAULT_DEBOUNCE_PERIOD 100_0000 //20ms for 100MHz

module keypad_unit_develop #(parameter 
    DEBOUNCE_PERIOD = `KEYPAD_DEFAULT_DEBOUNCE_PERIOD
    )(
    input wire clk, rst_n,
    
    input wire [3:0] row_in,
    output reg [3:0] col_out,
    
    output reg [7:0] key_coord
    );
    
    localparam  SCAN_COL1   = 2'b00,
                SCAN_COL2   = 2'b01,
                SCAN_COL3   = 2'b10,
                SCAN_COL4   = 2'b11;

    localparam  RESPONSE_PERIOD = DEBOUNCE_PERIOD / 8,
                SCAN_PERIOD     = DEBOUNCE_PERIOD / 4;
    
    reg [1:0] stage;
    reg [20:0] delay_duration;
    reg [3:0] row_val [3:0];
    
    integer i;
    always @(negedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                col_out,
                delay_duration,
                key_coord
            } <= 0;
            stage   <= SCAN_COL1;
            for (i = 0; i < 4; i = i + 1) begin
                row_val[i] <= 4'hf;
            end
        end else begin
            case  ({delay_duration % RESPONSE_PERIOD == 0,  // let out the next signal for scanning
                    delay_duration % SCAN_PERIOD == 0})     // check for changes by the scanning signal 
                2'b01  : begin
                    case (stage)
                        SCAN_COL1: col_out <= 4'b0111;
                        SCAN_COL2: col_out <= 4'b1011;
                        SCAN_COL3: col_out <= 4'b1101;
                        default  : col_out <= 4'b1110; // SCAN_COL4
                    endcase
                end
                2'b10  : begin
                    if (row_in != 4'hf & row_val[stage] == 4'hf) 
                        key_coord <= {col_out, row_in};
                    else 
                        key_coord <= key_coord;
                        // key_coord <= 0;
                    
                    row_val[stage] <= row_in;
                    stage <= stage + 1;
                end
                default: 
                    key_coord <= key_coord;
                    // key_coord <= 0;
            endcase
        end
    end
endmodule