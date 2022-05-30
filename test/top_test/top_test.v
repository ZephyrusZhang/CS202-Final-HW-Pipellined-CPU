module moduleName ();
    wire clk, rst_n, uart_in_progress, hsync, vsync, uart_tx, instruction_mem_no_op_input;
    wire [3:0] col_out;
    wire [7:0] seg_tube, seg_enable;
    wire [11:0] vga_signal;
    wire [31:0] instruction_mem_pc_input, instruction_mem_instruction_input;

    top_modified uut(
        clk, rst_n,
        0,
        0,                                         // for uart_unit
        4'b1111,
        col_out,
        seg_tube,   
        seg_enable,
        vga_signal,
        uart_in_progress,
        hsync, vsync,
        uart_tx,

        instruction_mem_no_op_input,
        instruction_mem_pc_input,
        instruction_mem_instruction_input
    );

    always begin
        clk = ~clk;
    end

    
endmodule