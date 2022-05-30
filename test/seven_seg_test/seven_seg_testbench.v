module seven_seg_testbench ();
    reg clk = 0, rst_n = 1;
    wire [7:0] seg_tube = 0, seg_enable = 0;
    reg [31:0] display_value = 0;

    seven_seg_unit seven_seg_unit(
        .clk(clk), .rst_n(rst_n),                               // note this is a clock for tube 1ms refresh
        .display_value(display_value),    // from keypad_unit (value to be displayed)
        .switch_enable(1'b0),                       // from keypad_unit (show binary switch input)
        .input_enable(1'b0),                        // from hazard_unit (whether to display)
        
        .seg_tube(seg_tube),                      // control signal for tube segments
        .seg_enable(seg_enable)                     // control signal for tube positions
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        #5 rst_n = 0;
        #5 rst_n = 1;
        #10 display_value = 10;
        #10 display_value = 30;
    end

endmodule