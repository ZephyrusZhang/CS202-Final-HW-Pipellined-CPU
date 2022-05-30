`timescale 1ns / 1ps

module top_test ();
    reg clk = 0, rst_n = 1, instruction_mem_no_op_input = 0;
    wire uart_in_progress = 0, hsync = 0, vsync = 0, uart_tx = 0;
    wire [3:0] col_out = 0;
    wire [7:0] seg_tube = 0, seg_enable = 0;
    wire [11:0] vga_signal = 0;
    reg [31:0] instruction_mem_pc_input = 0, instruction_mem_instruction_input = 0;

    top_modified uut(
        .clk_raw(clk), 
        .rst_n(rst_n),
        .switch_map(8'b0),
        .uart_rx(1'b0),                                         // for uart_unit
        .row_in(4'b1111),
        .col_out(col_out),
        .seg_tube(seg_tube),   
        .seg_enable(seg_enable),
        .vga_signal(vga_signal),
        .uart_in_progress(uart_in_progress),
        .hsync(hsync), 
        .vsync(vsync),
        .uart_tx(uart_tx),

        .instruction_mem_no_op_input(instruction_mem_no_op_input),
        .instruction_mem_pc_input(instruction_mem_pc_input),
        .instruction_mem_instruction_input(instruction_mem_instruction_input)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        #5 rst_n = 0;
        #5 
        #10 
            rst_n = 1;
        #10 
            instruction_mem_pc_input = 0;
            instruction_mem_instruction_input = 32'h8C020000;
        #10
            instruction_mem_pc_input = instruction_mem_pc_input + 4;
            instruction_mem_instruction_input = 32'h20080004;
        #10
            instruction_mem_pc_input = instruction_mem_pc_input + 4;
            instruction_mem_instruction_input = 32'had020000;
        #10
            instruction_mem_pc_input = instruction_mem_pc_input + 4;
            instruction_mem_instruction_input = 32'h08000000;
        
    end

endmodule