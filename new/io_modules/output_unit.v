`include "../definitions.v"
`timescale 1ns / 1ps

module input_unit (
    input clk_vga,
    
    input      display_en,
    input      [COORDINATE_WIDTH - 1:0] x,
    input      [COORDINATE_WIDTH - 1:0] y,

    input      vga_write_enable,                        // from data_mem (vga write enable)
    input      [`ISA_WIDTH - 1:0] vga_store_data,       // from data_mem (data to vga)

    input      [2:0] issue_type,                        // from hazard_unit (both hazard and interrupt)
    input      switch_enable,                           // from input_unit (user is using switches)

    output reg [`VGA_BIT_DEPTH - 1:0] vga               // VGA display signal
    );

    reg [`ISA_WIDTH - 1:0] value_to_display;

    always @(*) begin
        if (vga_write_enable) 
            value_to_display <= vga_store_data;
        else
            value_to_display <= value_to_display;
    end
    
    wire [`VGA_BIT_DEPTH - 1:0] zero_rgb, 
                                one_rgb, 
                                keypad_rgb, 
                                normal_rgb, 
                                switch_rgb, 
                                uart_rgb;
    
    wire digits_box_clear = (y < `DIGITS_BOX_Y) | (x < `DIGITS_BOX_X);
    wire digits_clear     = (y < `DIGITS_Y)     | (x < `DIGITS_X);
    wire status_clear     = (y < `STATUS_Y)     | (x < `STATUS_X);

    wire [`DIGIT_H_WIDTH]  y_digit  = (y - `DIGITS_Y) % `DIGITS_HEIGHT;
    wire [`DIGIT_W_WIDTH]  x_digit  = (x - `DIGITS_X) % `DIGIT_WIDTH;
    wire [`STATUS_H_WIDTH] y_status = (y - `STATUS_Y) % `STATUS_HEIGHT;
    wire [`STATUS_W_WIDTH] x_status = (x - `STATUS_X) % `STATUS_WIDTH;

    // block memory for each asset to be displayed
    zero_rom    ZERO_rom    (.clk(clk), .row(y_digit),  .col(x_digit),  .color_data(zero_rgb));
    one_rom     ONE_rom     (.clk(clk), .row(y_digit),  .col(x_digit),  .color_data(one_rgb));
    keypad_rom  Keypad_rom  (.clk(clk), .row(y_status), .col(x_status), .color_data(keypad_rgb));
    normal_rom  Normal_rom  (.clk(clk), .row(y_status), .col(x_status), .color_data(normal_rgb));
    switch_rom  switch_rom  (.clk(clk), .row(y_status), .col(x_status), .color_data(switch_rgb));
    uart_rom    uart_rom    (.clk(clk), .row(y_status), .col(x_status), .color_data(uart_rgb));
    
    

    reg [3:0] state, next_state;
    reg [(INPUT_DATA_WIDTH / 2) - 1:0] data_temp;
    reg [POSITION_WIDTH - 1:0] black_index_reg;
    reg [(POSITION_SIZE * POSITION_WIDTH) - 1:0] position_reg;
    
    wire [COORDINATE_WIDTH - 1:0] x_segment_pixel, x_local_index, x_local_index_next, x_global_index, x_global_index_next,
                                  y_segment_pixel, y_local_index, y_local_index_next, y_global_index, y_global_index_next;
    
    assign x_segment_pixel     = picture_width / h_seg_count;
    assign x_local_index       = (x - X_GAP) % x_segment_pixel;
    assign x_local_index_next  = (x - X_GAP + 1) % x_segment_pixel;
    assign x_global_index      = (x - X_GAP) / x_segment_pixel;
    assign x_global_index_next = (x - X_GAP + 1) / x_segment_pixel;
    
    assign y_segment_pixel     = picture_height / v_seg_count;
    assign y_local_index       = (y - Y_GAP) % y_segment_pixel;
    assign y_local_index_next  = (y - Y_GAP + 1) % y_segment_pixel;
    assign y_global_index      = (y - Y_GAP) / y_segment_pixel;
    assign y_global_index_next = (y - Y_GAP + 1) / y_segment_pixel;
    
    reg [POSITION_WIDTH - 1:0] display_index, display_index_next;
    
    

    always @(posedge clk_vga) begin
        if (!rst_n) begin
            addr_out <= 0;
            display_index <= 0;
        end else if (display_en)
            casex (region_state)
                8'b0X1X_00XX, 8'bX0X1_00XX: vga <= BORDER_COLOR; // above at upper border or below at lower border
                8'bXX00_0X1X, 8'bXX00_X0X1: begin // sides of the frame
                    vga <= BORDER_COLOR;
                    // predict first contact
                    addr_out <= ((((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                              + y_local_index) * PICTURE_WIDTH)
                              + ((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                end
                8'bXX00_XX00: begin // in picture frame
                    if (display_index == black_index_reg) vga <= 0;
                    else vga <= data_out;
                    casex (pixel_state)
                        4'b11XX: begin // one pixel before bottom right
                            display_index <= 0;
                            addr_out <= ((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel * PICTURE_WIDTH)
                                      + ((position_reg[(display_index * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        4'b10X0: begin // at the end of one row but still in the same row segment
                            display_index <= display_index - h_seg_count + 1;
                            addr_out <= ((((position_reg[((display_index - h_seg_count + 1) * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                                      + y_local_index_next) * PICTURE_WIDTH)
                                      + ((position_reg[((display_index - h_seg_count + 1) * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        4'b10X1: begin // end of row segment
                            display_index <= display_index + 1;
                            addr_out <= (((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                                      * PICTURE_WIDTH)
                                      + ((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        4'b0X1X: begin // end of one block segment
                            display_index <= display_index + 1;
                            addr_out <= ((((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] / h_seg_count) * y_segment_pixel)
                                      + y_local_index) * PICTURE_WIDTH)
                                      + ((position_reg[((display_index + 1) * POSITION_WIDTH)+:POSITION_WIDTH] % h_seg_count) * x_segment_pixel);
                        end
                        default: addr_out <= addr_out + 1; // in regional block
                    endcase
                end
                default: vga <= BACKGROUND_COLOR; // outside the frame
            endcase
        else vga <= 0;
    end

endmodule

endmodule