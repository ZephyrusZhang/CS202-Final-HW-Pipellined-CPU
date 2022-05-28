module keypad_testbench ();
    reg [3:0] row_in = 4'hf;
    wire [3:0] col_out;
    reg clk = 0, rst_n = 1;
    wire key_pressed;
    wire [7:0] key_coord;

    keypad_unit uut(clk, rst_n, row_in, col_out, key_pressed, key_coord);

    initial begin
        #10 rst_n = 0;
        #10 rst_n = 1;
        #50 row_in = 4'b1101;
    end

    always begin
        #10 clk = ~clk;
    end
endmodule