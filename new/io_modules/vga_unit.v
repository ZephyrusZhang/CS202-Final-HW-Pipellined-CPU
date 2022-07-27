`include "../definitions.v"
`timescale 1ns / 1ps

module vga_unit (
        input  clk_vga, rst_n,

        output hsync, vsync, display_en,
        output [`COORDINATE_WIDTH - 1:0] x, y
    );
               
    localparam  TOTAL_WIDTH      = `DISPLAY_WIDTH   + `LEFT_BORDER + `RIGHT_BORDER  + `HORIZONTAL_GAP,
                TOTAL_HEIGHT     = `DISPLAY_HEIGHT  + `TOP_BORDER  + `BOTTOM_BORDER + `VERTICAL_GAP,
                HORIZONTAL_START = `HORIZONTAL_GAP  + `LEFT_BORDER,
                VERTICAL_START   = `VERTICAL_GAP    + `TOP_BORDER,
                HORIZONTAL_END   = HORIZONTAL_START + `DISPLAY_WIDTH,
                VERTICAL_END     = VERTICAL_START   + `DISPLAY_HEIGHT;
    
    reg [9:0] global_x, global_y;
    always @(posedge clk_vga, negedge rst_n) begin
        if (~rst_n) begin
            global_x <= 0;
            global_y <= 0;
        end else if (global_x == TOTAL_WIDTH) begin
            global_x <= 0;

            if (global_y == TOTAL_HEIGHT) global_y <= 0;
            else                          global_y <= global_y + 1;
        end else 
            global_x <= global_x + 1;
    end

    assign hsync = (`HORIZONTAL_GAP <= global_x);
    assign vsync = (`VERTICAL_GAP   <= global_y);
    
    assign x = global_x - HORIZONTAL_START;
    assign y = global_y - VERTICAL_START;
    
    assign display_en = (HORIZONTAL_START <= global_x) & (global_x < HORIZONTAL_END) &
                        (VERTICAL_START   <= global_y) & (global_y < VERTICAL_END);

endmodule