`include "../definitions.v"
`timescale 1ns / 1ps

module vga_unit (
        input  clk_vga, rst_n,

        output hsync, vsync, display_en,
        output [`COORDINATE_WIDTH - 1:0] x, y
    );
               
    localparam TOTAL_WIDTH  = `DISPLAY_WIDTH  + `LEFT_BORDER + `RIGHT_BORDER +  `H_RETRACE,
               TOTAL_HEIGHT = `DISPLAY_HEIGHT + `TOP_BORDER  + `BOTTOM_BORDER + `V_RETRACE,
               START_H      = `H_RETRACE + `LEFT_BORDER,
               START_V      = `V_RETRACE + `TOP_BORDER,
               END_H        = START_H + `DISPLAY_WIDTH,
               END_V        = START_V + `DISPLAY_HEIGHT;
    
    reg [9:0] x_global, y_global;
    always @(posedge clk_vga, negedge rst_n) begin
        if (~rst_n) begin
            x_global <= 0;
            y_global <= 0;
        end else begin
            if (x_global == TOTAL_WIDTH) begin
                x_global <= 0;

                if (y_global == TOTAL_HEIGHT) y_global <= 0;
                else                          y_global <= y_global + 1;
            end else 
                x_global <= x_global + 1;
        end
    end

    assign hsync = (`H_RETRACE <= x_global);
    assign vsync = (`V_RETRACE <= y_global);
    
    assign x = x_global - START_H;
    assign y = y_global - START_V;
    
    assign display_en = (START_H  <= x_global) & 
                        (START_V  <= y_global) &
                        (x_global < END_H)     & 
                        (y_global < END_V);
    
endmodule