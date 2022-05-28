module vga_top (
    input clk, rst_n
    );
    wire clk_vga;

    module clk_generator #(parameter 
    PERIOD = `DEFAULT_PERIOD
    )(
    input wire clk, rst_n,
    .clk_out(clk_vga));

    input_unit unit_under_test(
        .clk_vga(clk_vga), 
        .rst_n(),
    
    input      display_en,
    input      [`COORDINATE_WIDTH - 1:0] x, y,

    input      vga_write_enable,                        // from data_mem (vga write enable)
    input      [`ISA_WIDTH - 1:0] vga_store_data,       // from data_mem (data to vga)

    input      [2:0] issue_type,                        // from hazard_unit (both hazard and interrupt)
    input      switch_enable,                           // from input_unit (user is using switches)

    output reg [`VGA_BIT_DEPTH - 1:0] vga_rgb           // VGA display signal
    );
endmodule