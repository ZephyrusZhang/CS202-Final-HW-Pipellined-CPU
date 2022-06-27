`include "../definitions.v"
`timescale 1ns / 1ps

module output_unit (
    input clk, rst_n,
    
    input      display_en,
    input      [`COORDINATE_WIDTH - 1:0] x, y,

    input      vga_write_enable,                        // from data_mem (vga write enable)
    input      [`ISA_WIDTH - 1:0] vga_store_data,       // from data_mem (data to vga)

    input      [`ISSUE_TYPE_WIDTH - 1:0] issue_type,    // from hazard_unit (both hazard and interrupt)
    input      switch_enable,                           // from input_unit (user is using switches)

    output reg [`VGA_BIT_DEPTH - 1:0] vga_rgb           // VGA display signal
    );

    reg [`ISA_WIDTH - 1:0] value_to_display;

    always @(negedge clk, negedge rst_n) begin
        if (~rst_n)                value_to_display <= 0;
        else if (vga_write_enable) value_to_display <= vga_store_data;
        else                       value_to_display <= value_to_display;
    end
    
    wire [`VGA_BIT_DEPTH - 1:0] zero_rgb, 
                                one_rgb, 
                                normal_rgb, 
                                uart_rgb,
                                pause_rgb,
                                keypad_rgb, 
                                switch_rgb,
                                fallthrough_rgb;
    
    wire [`DIGIT_H_WIDTH - 1:0]  y_digits = (y - `DIGITS_Y);                    // y coordinate inside the digits area
    wire [`DIGITS_W_WIDTH - 1:0] x_digits = (x - `DIGITS_X);                    // x coordinate inside the digits area
    wire [`DIGIT_W_WIDTH - 1:0]  x_digit  = (x - `DIGITS_X) % `DIGIT_WIDTH;     // x coordinate inside each digit area

    wire [`STATUS_H_WIDTH - 1:0] y_status = (y - `STATUS_Y);                    // y coordinate inside the status area
    wire [`STATUS_W_WIDTH - 1:0] x_status = (x - `STATUS_X);                    // x coordinate inside the status area
    
    wire [`DIGITS_IDX_WIDTH - 1:0] digits_idx = (x_digits / `DIGIT_WIDTH);      // index for digit to be displayed (with blanks)
    wire [`DIGITS_IDX_WIDTH - 1:0] digit_idx  = digits_idx - (digits_idx / 5);  // index for digit to be displayed (without blanks)
    
    // outside the digits box
    wire digits_box_clear = (y <= `DIGITS_BOX_Y) | (x <= `DIGITS_BOX_X) | (`DIGITS_BOX_Y + `DIGITS_BOX_HEIGHT <= y) | (`DIGITS_BOX_X + `DIGITS_BOX_WIDTH <= x);
    wire digits_clear     = (y <= `DIGITS_Y)     | (x <= `DIGITS_X)     | (`DIGITS_Y     + `DIGITS_HEIGHT     <= y) | (`DIGITS_X     + `DIGITS_WIDTH     <= x)
                            | ((digits_idx + 1) % 5 == 0);  // inside the digits box but not displaying digits
    // outside the status box
    wire status_clear     = (y <= `STATUS_Y)     | (x <= `STATUS_X)     | (`STATUS_Y     + `STATUS_HEIGHT     <= y) | (`STATUS_X     + `STATUS_WIDTH     <= x);

    // block memory for "0" "1" to be displayed
    ZERO_rom    zero_rom    (.clk(clk), .row(y_digits), .col(x_digit) , .color_data(zero_rgb));
    ONE_rom     one_rom     (.clk(clk), .row(y_digits), .col(x_digit) , .color_data(one_rgb));
    
    // block memory for type of issue to be displayed
    Normal_rom      normal_rom      (.clk(clk), .row(y_status), .col(x_status), .color_data(normal_rgb));
    UART_rom        uart_rom        (.clk(clk), .row(y_status), .col(x_status), .color_data(uart_rgb));
    Pause_rom       pause_rom       (.clk(clk), .row(y_status), .col(x_status), .color_data(pause_rgb));
    Keypad_rom      keypad_rom      (.clk(clk), .row(y_status), .col(x_status), .color_data(keypad_rgb));
    Switch_rom      switch_rom      (.clk(clk), .row(y_status), .col(x_status), .color_data(switch_rgb));
    Fallthrough_rom fallthrough_rom (.clk(clk), .row(y_status), .col(x_status), .color_data(fallthrough_rgb));
    
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            vga_rgb <= 0;
        end else if (display_en) begin
            case ({status_clear, digits_box_clear, digits_clear})
                // status box reached
                3'b011 : begin
                    case (issue_type)
                        `ISSUE_NONE       : vga_rgb <= normal_rgb;
                        `ISSUE_UART       : vga_rgb <= uart_rgb;
                        `ISSUE_PAUSE      : vga_rgb <= pause_rgb;
                        `ISSUE_FALLTHROUGH: vga_rgb <= fallthrough_rgb;
                        `ISSUE_KEYPAD     :
                            if (switch_enable) vga_rgb <= switch_rgb;
                            else               vga_rgb <= keypad_rgb;
                        default           : vga_rgb <= `BG_COLOR;
                    endcase
                end
                // digits box reached
                3'b101 : vga_rgb <= `DIGITS_BOX_BG_COLOR;
                // digits reached
                3'b100 : 
                    if (value_to_display[(`ISA_WIDTH - digit_idx - 1)+:1] == 1'b1) 
                        vga_rgb <= one_rgb;
                    else
                        vga_rgb <= zero_rgb;
                // outside the text area
                default: vga_rgb <= `BG_COLOR;
            endcase
        end else 
            vga_rgb <= 0;
    end

endmodule