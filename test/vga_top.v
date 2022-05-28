`include "../definitions.v"

module vga_top (
    input clk, rst_n,
    input vga_write_enable, switch_enable,
    output hsync, vsync,
    output [`VGA_BIT_DEPTH - 1:0] vga_rgb
    );
    wire clk_vga;
    wire display_en;
    wire [`COORDINATE_WIDTH - 1:0] x, y;

    clk_generator #(4) cloker(
        .clk(clk), 
        .rst_n(rst_n),
        .clk_out(clk_vga)
    );

    output_unit output_test(
        .clk_vga(clk_vga),
        .rst_n(rst_n),
        .display_en(display_en),
        .x(x), y(y),
        .vga_write_enable(vga_write_enable),
        .vga_store_data(32'h8000_0008),
        .issue_type(`KEYPAD),
        .switch_enable(switch_enable),
        .vga_rgb(vga_rgb)
    );

    vga_signal vga_uut(
        .clk_vga(clk_vga), 
        .rst_n(rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_en(display_en),
        .x(x), .y(y)
    );
endmodule