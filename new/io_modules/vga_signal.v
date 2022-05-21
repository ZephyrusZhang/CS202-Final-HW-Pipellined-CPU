`timescale 1ns / 1ps


module vga_signal #(parameter
        DISPLAY_WIDTH = 640,
        DISPLAY_HEIGHT = 480,
        LEFT_BORDER = 48,
        RIGHT_BORDER = 16,
        TOP_BORDER = 33,
        BOTTOM_BORDER = 10,
        H_RETRACE = 96, // horizontal
        V_RETRACE = 2    //vertical
    )(
        input wire clk, rst_n,
        output wire hsync, vsync, display_en,
        output wire [9:0] x, y
    );
               
    localparam TOTAL_WIDTH = DISPLAY_WIDTH + LEFT_BORDER + RIGHT_BORDER + H_RETRACE,
               TOTAL_HEIGHT = DISPLAY_HEIGHT + TOP_BORDER + BOTTOM_BORDER + V_RETRACE,
               START_H = H_RETRACE + LEFT_BORDER,
               START_V = V_RETRACE + TOP_BORDER,
               END_H = START_H + DISPLAY_WIDTH,
               END_V = START_V + DISPLAY_HEIGHT;
    
    reg [9:0] x_global, y_global;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            x_global <= 0;
            y_global <= 0;
        end else begin
            if (x_global == TOTAL_WIDTH) begin
                x_global <= 0;
                if (y_global == TOTAL_HEIGHT) y_global <= 0;
                else y_global <= y_global + 1;
            end else x_global <= x_global + 1;
        end
    end

    assign hsync = H_RETRACE <= x_global;
    assign vsync = V_RETRACE <= y_global;
    
    assign x = x_global - START_H;
    assign y = y_global - START_V;
    
    assign display_en = (START_H <= x_global) && (x_global < END_H) && (START_V <= y_global) && (y_global < END_V);
    
//    reg [1:0] pixel_reg;
//    wire [1:0] pixel_next;
    
//    always @(posedge clk, negedge rst_n)
//        if(!rst_n) pixel_reg <= 0;
//        else pixel_reg <= pixel_next;
        
//    assign pixel_next = pixel_reg + 1;
//    assign pixel_tick = (pixel_reg == 0);
    
//    reg [9:0] h_count_reg, h_count_next, v_count_reg, v_count_next;
//    reg vsync_reg, hsync_reg;
//    wire vsync_next, hsync_next;
    
//    always @(posedge clk, negedge rst_n) begin
//        if(!rst_n) begin
//            v_count_reg <= 0;
//            h_count_reg <= 0;
//            vsync_reg <= 0;
//            hsync_reg <= 0;
//        end else begin
//            v_count_reg <= v_count_next;
//            h_count_reg <= h_count_next;
//            vsync_reg <= vsync_next;
//            hsync_reg <= hsync_next;
//        end
//    end
    
//    always @* begin
//        if(pixel_tick) 
//            if(h_count_reg == TOTAL_WIDTH) h_count_next = 0;
//            else h_count_next = h_count_reg + 1;
//        else h_count_next = h_count_reg;
        
//        if(pixel_tick && h_count_reg == TOTAL_WIDTH)
//            if(v_count_reg == TOTAL_HEIGHT) v_count_next = 0;
//            else v_count_next = v_count_reg + 1;
//        else v_count_next = v_count_reg;
//    end
    
//    assign hsync_next = (h_count_reg >= START_H_RETRACE && h_count_reg <= END_H_RETRACE);
//    assign vsync_next = (v_count_reg >= START_V_RETRACE && v_count_reg <= END_V_RETRACE);
    
//    assign hsync = hsync_reg;
//    assign vsync = vsync_reg;
    
endmodule

