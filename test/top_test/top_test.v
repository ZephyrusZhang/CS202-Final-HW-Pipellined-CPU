module moduleName ();
    wire clk = 0, rst_n = 0, uart_in_progress, hsync, vsync, uart_tx, instruction_mem_no_op_input = 0;
    wire [3:0] col_out;
    wire [7:0] seg_tube, seg_enable;
    wire [11:0] vga_signal;
    wire [31:0] instruction_mem_pc_input = 0, instruction_mem_instruction_input = 0;

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
        #5 clk = ~clk;
    end

    initial begin
        #5 rst_n = 1;
        #5 rst_n = 0;
        #10 
            instruction_mem_pc_input = 0;
            instruction_mem_instruction_input = 32'h8C020000;
        #10
            instruction_mem_pc_input = instruction_mem_pc_input + 1;
            instruction_mem_instruction_input = 32'h20080004;
        #10
            instruction_mem_pc_input = instruction_mem_pc_input + 1;
            instruction_mem_instruction_input = 32'had020000;
        #10
            instruction_mem_pc_input = instruction_mem_pc_input + 1;
            instruction_mem_instruction_input = 32'h08000000;
        
    end

endmodule