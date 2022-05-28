`timescale 1ns / 1ps
`define KEYPAD_DEFAULT_DEBOUNCE_PERIOD 200_0000 //20ms for 100MHz

module keypad_unit_develop #(parameter 
    DEBOUNCE_PERIOD = `KEYPAD_DEFAULT_DEBOUNCE_PERIOD
    )(
    input wire clk, rst_n,
    
    input wire [3:0] row_in,
    output reg [3:0] col_out,
    
    output reg [7:0] key_coord
    );
    
    reg [7:0] key_coord_1, key_coord_2;
    
    localparam  IDLE        = 4'b0000,
                SCAN_COL1_1 = 4'b0001,
                SCAN_COL2_1 = 4'b0010,
                SCAN_COL3_1 = 4'b0011,
                SCAN_COL4_1 = 4'b0100,
                DELAY       = 4'b0110,
                SCAN_COL1_2 = 4'b0111,
                SCAN_COL2_2 = 4'b1000,
                SCAN_COL3_2 = 4'b1001,
                SCAN_COL4_2 = 4'b1010,
                CHECK       = 4'b1011;
    
    reg [2:0] state;
    reg [20:0] delay_cnt;
    
    always @(negedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                col_out,
                delay_cnt,
                key_coord_1,
                key_coord_2,
                key_coord
            } <= 0;
        end else begin
            case (state)
                IDLE: begin
                    key_coord       <= 0;
                    if (row_in != 4'hf) begin
                        state       <= SCAN_COL1_1;
                        col_out     <= 4'b0111;
                    end else
                        state       <= state;
                end
                // start scanning for the first time
                SCAN_COL1_1:
                    if (row_in != 4'hf) begin
                        state       <= DELAY;
                        key_coord_1 <= {row_in, col_out};
                    end else begin
                        state       <= SCAN_COL2_1;
                        col_out     <= 4'b1011;
                    end
                SCAN_COL2_1:
                    if (row_in != 4'hf) begin
                        state       <= DELAY;
                        key_coord_1 <= {row_in, col_out};
                    end else begin
                        state       <= SCAN_COL3_1;
                        col_out     <= 4'b1101;
                    end
                SCAN_COL3_1:
                    if (row_in != 4'hf) begin
                        state       <= DELAY;
                        key_coord_1 <= {row_in, col_out};
                    end else begin
                        state       <= SCAN_COL4_1;
                        col_out     <= 4'b1110;
                    end
                SCAN_COL4_1:
                    if (row_in != 4'hf) begin
                        state       <= DELAY;
                        key_coord_1 <= {row_in, col_out};
                    end else begin
                        state       <= IDLE;
                        col_out     <= 4'b0000;
                    end
                // pause and wait
                DELAY: begin
                    delay_cnt       <= delay_cnt + 1;
                    if (row_in != 4'hf & delay_cnt == DEBOUNCE_PERIOD) 
                        state       <= SCAN_COL1_2;
                    else
                        state       <= IDLE;
                end
                // scan the second time
                SCAN_COL1_2:
                    if (row_in != 4'hf) begin
                        state       <= CHECK;
                        key_coord_2 <= {row_in, col_out};
                    end else begin
                        state       <= SCAN_COL2_2;
                        col_out     <= 4'b1011;
                    end
                SCAN_COL2_2:
                    if (row_in != 4'hf) begin
                        state       <= CHECK;
                        key_coord_2 <= {row_in, col_out};
                    end else begin
                        state       <= SCAN_COL3_2;
                        col_out     <= 4'b1101;
                    end
                SCAN_COL3_2:
                    if (row_in != 4'hf) begin
                        state       <= CHECK;
                        key_coord_2 <= {row_in, col_out};
                    end else begin
                        state       <= SCAN_COL4_2;
                        col_out     <= 4'b1110;
                    end
                SCAN_COL4_2:
                    if (row_in != 4'hf) begin
                        state       <= CHECK;
                        key_coord_2 <= {row_in, col_out};
                    end else begin
                        state       <= IDLE;
                        col_out     <= 4'b0000;
                    end
                // check the result and compare two scans
                CHECK: begin
                    if (key_coord_1 == key_coord_2) begin
                        key_coord   <= key_coord_2;
                        key_coord_1 <= 0;
                        key_coord_2 <= 0;
                    end
                        state       <= IDLE;
                end
                default: state      <= IDLE;
            endcase
        end
    end
endmodule