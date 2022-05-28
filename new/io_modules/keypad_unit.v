`timescale 1ns / 1ps
`define KEYPAD_DEFAULT_DEBOUNCE_PERIOD 100_0000 //20ms for 100MHz

module keypad_unit #(parameter 
    DEBOUNCE_PERIOD = `KEYPAD_DEFAULT_DEBOUNCE_PERIOD
    )(
    input wire clk, rst_n,
    
    input wire [3:0] row_in,
    output reg [3:0] col_out,
    
    output reg [7:0] key_coord
    );
    
    reg [5:0] keypad_state, keypad_next_state;
    
    wire key_pressed;
    reg [3:0] col_val, row_val;
    
    localparam SCAN_IDLE     = 8'b0000_0001,
               SCAN_JITTER_1 = 8'b0000_0010,
               SCAN_COL1     = 8'b0000_0100,
               SCAN_COL2     = 8'b0000_1000,
               SCAN_COL3     = 8'b0001_0000,
               SCAN_COL4     = 8'b0010_0000,
               SCAN_READ     = 8'b0100_0000,
               SCAN_JITTER_2 = 8'b1000_0000;
    localparam DELAY_TRAN = 2;
    
    reg [20:0] delay_cnt;
    wire delay_done;
    
    reg [7:0] pre_state;
    reg [7:0] next_state;
    reg [20:0] tran_cnt;
    wire tran_flag;
    
    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) delay_cnt <= 'd0;
        else if (delay_cnt == DEBOUNCE_PERIOD) delay_cnt <= 'd0;
        else if (next_state == SCAN_JITTER_1 | next_state == SCAN_JITTER_2) begin
            delay_cnt <= delay_cnt + 1'b1;
        end else delay_cnt <= 'd0;
    end
    
    assign delay_done = (delay_cnt == DEBOUNCE_PERIOD - 1'b1) ? 1'b1 : 1'b0;
    
    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) begin
            tran_cnt <= 'd0;
        end else if (tran_cnt == DELAY_TRAN) begin
            tran_cnt <= 'd0;
        end else tran_cnt <= tran_cnt + 1'b1;
    end
    
    assign tran_flag = (tran_cnt == DELAY_TRAN) ? 1'b1 : 1'b0;
    
    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) begin
            pre_state <= SCAN_IDLE;
        end else if (tran_flag) begin
            pre_state <= next_state;
        end else pre_state <= pre_state;
    end
    
    always @(*) begin
        next_state = SCAN_IDLE;
        case (pre_state)
            SCAN_IDLE:
                if (row_in != 4'hf) next_state = SCAN_JITTER_1;
                else next_state = SCAN_IDLE;
            SCAN_JITTER_1:
                if (row_in != 4'hf && delay_done) next_state = SCAN_COL1;
                else next_state = SCAN_JITTER_1;
            SCAN_COL1:
                if (row_in != 4'hf) next_state = SCAN_READ;
                else next_state = SCAN_COL2;
            SCAN_COL2:
                if (row_in != 4'hf) next_state = SCAN_READ;
                else next_state = SCAN_COL3;
            SCAN_COL3:
                if (row_in != 4'hf) next_state = SCAN_READ;
                else next_state = SCAN_COL4;
            SCAN_COL4:
                if (row_in != 4'hf) next_state = SCAN_READ;
                else next_state = SCAN_IDLE;
            SCAN_READ:
                if (row_in != 4'hf) next_state = SCAN_JITTER_2;
                else next_state = SCAN_IDLE;
            SCAN_JITTER_2:
                if (row_in != 4'hf && delay_done) next_state = SCAN_IDLE;
                else next_state = SCAN_JITTER_2;
            default: next_state = SCAN_IDLE;
        endcase
    end
    
    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) begin
            col_out <= 4'h0;
            row_val <= 4'h0;
            col_val <= 4'h0;
        end else if (tran_flag) begin
            case (next_state)
                SCAN_COL1: col_out <= 4'b0111;
                SCAN_COL2: col_out <= 4'b1011;
                SCAN_COL3: col_out <= 4'b1101;
                SCAN_COL4: col_out <= 4'b1110;
                SCAN_READ: begin
                    col_out <= col_out;
                    row_val <= row_in;
                    col_val <= col_out;
                end
                default: col_out <= 4'b0000;
            endcase
        end else begin
            col_out <= col_out;
            row_val <= row_val;
            col_val <= col_val;
        end
    end
    
    assign key_pressed = (next_state == SCAN_IDLE && pre_state == SCAN_JITTER_2 && tran_flag) ? 1'b1 : 1'b0;
    
    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) begin
            key_coord <= 0; 
        end else if (key_pressed) begin
            key_coord <= {row_val, col_val};
        end else 
            // key_coord <= key_coord; // critical: annotate when not testing!
            key_coord <= 0; // this is the correct handling operation
    end
endmodule