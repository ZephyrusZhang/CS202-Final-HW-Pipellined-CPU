`timescale 1ns / 1ps

module top_testbench ();
    reg  clk = 0, rst_n = 1;
    wire uart_in_progress = 0, hsync = 0, vsync = 0, uart_tx = 0;
    wire [3:0]  col_out;
    wire [7:0]  seg_tube, seg_enable;
    wire [11:0] vga_signal;

    localparam  COL_1 = 4'b0111,
                COL_2 = 4'b1011,
                COL_3 = 4'b1101,
                COL_4 = 4'b1110,
                ROW_1 = 4'b0111,
                ROW_2 = 4'b1011,
                ROW_3 = 4'b1101,
                ROW_4 = 4'b1110,
                NONE  = 4'b1111;
    
    localparam  ZERO      = 4'd0,
                ONE       = 4'd1,
                TWO       = 4'd2,
                THREE     = 4'd3,
                FOUR      = 4'd4,
                FIVE      = 4'd5,
                SIX       = 4'd6,
                SEVEN     = 4'd7,
                EIGHT     = 4'd8,
                NINE      = 4'd9,
                BACKSPACE = 4'd10, // "*": deletes the last digit
                ENTER     = 4'd11, // "#": comfirmes the input with leading zeros
                PAUSE     = 4'd12, // "A": pause and resume cpu execution
                SWITCH    = 4'd13, // "B": change input between switches and keypad
                NO_KEY    = 4'd14;

    localparam  KEYPRESS_CNT = 40;

    reg  [3:0]  row_in = 4'hf;
    reg  [15:0] row_in_reg = 16'hffff;
    reg  [3:0]  keys [KEYPRESS_CNT - 1:0];
    
    top uut(
        .clk_raw            (clk),
        .rst_n              (rst_n),
        .switch_map         (8'b1111_1111),
        .uart_rx            (1'b0),
        .row_in             (row_in),
        .col_out            (col_out),
        .seg_tube           (seg_tube),   
        .seg_enable         (seg_enable),
        .vga_signal         (vga_signal),
        .uart_in_progress   (uart_in_progress),
        .hsync              (hsync), 
        .vsync              (vsync),
        .uart_tx            (uart_tx)
    );

    // simulate clock
    always begin
        #5 clk = ~clk;
    end

    // reset
    initial begin
        #5 rst_n = 0;
        #5 rst_n = 1;
    end

    function [15:0] press_key(input [3:0] key);
        case (key)
                                /* {COL_4, COL_3, COL_2, COL_1} */ 
            ZERO     : press_key = {NONE,  NONE,  ROW_4, NONE };
            ONE      : press_key = {NONE,  NONE,  NONE,  ROW_1};
            TWO      : press_key = {NONE,  NONE,  ROW_1, NONE };
            THREE    : press_key = {NONE,  ROW_1, NONE,  NONE };
            FOUR     : press_key = {NONE,  NONE,  NONE,  ROW_2};
            FIVE     : press_key = {NONE,  NONE,  ROW_2, NONE };
            SIX      : press_key = {NONE,  ROW_2, NONE,  NONE };
            SEVEN    : press_key = {NONE,  NONE,  NONE,  ROW_3};
            EIGHT    : press_key = {NONE,  NONE,  ROW_3, NONE };
            NINE     : press_key = {NONE,  ROW_3, NONE,  NONE };
            BACKSPACE: press_key = {NONE,  NONE,  NONE,  ROW_4};
            ENTER    : press_key = {NONE,  ROW_4, NONE,  NONE };
            PAUSE    : press_key = {ROW_1, NONE,  NONE,  NONE };
            SWITCH   : press_key = {ROW_2, NONE,  NONE,  NONE };
            default  : press_key = {NONE,  NONE,  NONE,  NONE };
        endcase
    endfunction

    // simulate key-press
    integer i;
    initial begin
        for (i = 0; i < KEYPRESS_CNT; i = i + 1) keys[i] = NO_KEY;
        keys[0]  = ZERO;        // case 0
        keys[1]  = ENTER;
        keys[2]  = THREE;       // 3 numbers
        keys[3]  = ENTER;
        keys[4]  = THREE;       // 3
        keys[5]  = ENTER;
        keys[6]  = TWO;         // 2
        keys[7]  = ENTER;
        keys[8]  = ONE;         // 1
        keys[9]  = ENTER;
        keys[10] = ONE;         // case 1
        keys[11] = ENTER;
        keys[12] = TWO;         // case 2
        keys[13] = ENTER;
        keys[14] = THREE;       // case 3
        keys[15] = ENTER;
        keys[16] = FOUR;        // case 4
        keys[17] = ENTER;
        keys[18] = FIVE;        // case 5
        keys[19] = ENTER;
        keys[20] = SIX;         // case 6
        keys[21] = ENTER;
        keys[22] = ONE;         // 1st dataset
        keys[23] = ENTER;
        keys[24] = ZERO;        // 0th number
        keys[25] = ENTER;
        keys[26] = SEVEN;       // case 7
        keys[27] = ENTER;
        keys[28] = ONE;         // 1st number
        keys[29] = ENTER;
    end
    reg counter = 0;
    initial begin
        for (i = 0; i < KEYPRESS_CNT; i = i + 1) begin
            row_in_reg = press_key(keys[i]);

            repeat(4) begin
                row_in = NONE ; #625010;
            end
            
            repeat(2) begin
                row_in = row_in_reg[ 3: 0]; #625010; // COL_1
                row_in = row_in_reg[ 7: 4]; #625010; // COL_2
                row_in = row_in_reg[11: 8]; #625010; // COL_3
                row_in = row_in_reg[15:12]; #625010; // COL_4
            end
        end
        
        // // no input next period, simulate release
        // repeat(4) begin
        //     row_in = NONE ; #625010;
        // end
        // // simulate two consequtive press
        // repeat(2) begin
        //     row_in = ROW_2; #625010; // COL_1
        //     row_in = NONE ; #625010; // COL_2
        //     row_in = NONE ; #625010; // COL_3
        //     row_in = NONE ; #625010; // COL_4
        // end
    end

endmodule