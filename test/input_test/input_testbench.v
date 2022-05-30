module input_testbench ();
    reg clk = 0, rst_n = 1, instruction_mem_no_op_input = 0;
    wire uart_in_progress, input_complete_led, cpu_pause_led;
    wire [3:0] col_out = 0;
    wire [7:0] seg_tube = 0, seg_enable = 0;
    wire [11:0] vga_signal = 0;
    reg [31:0] instruction_mem_pc_input = 0, instruction_mem_instruction_input = 0;

    input_top uut(
        .clk(clk), .rst_n(rst_n),
        .row_in(row_in),
        .switch_map(8'b10101010),
        .col_out(col_out),
        .seg_tube(seg_tube),
        .seg_enable(seg_enable),
        .input_complete_led(input_complete_led),
        .cpu_pause_led(cpu_pause_led)
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
            row_in = 4'hf;
        #10
            row_in = 4'b1011;
    end

endmodule