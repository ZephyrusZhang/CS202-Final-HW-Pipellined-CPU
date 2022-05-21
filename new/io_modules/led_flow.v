`timescale 1ns / 1ps
`define LED_DEFAULT_DELAY_PERIOD 20_0000

module led_flow #(parameter
    DELAY_PERIOD = `LED_DEFAULT_DELAY_PERIOD
    )(
    input wire clk, rst_n,
    input wire enable,
    output reg [23:0] led
    );
    
    wire clk_led;
    clk_generator #(DELAY_PERIOD) led_clk_generator(clk, rst_n, clk_led);
    
    reg direction;
    reg [23:0] led_reg;
    
    always @(posedge clk_led or negedge rst_n)
        if (!rst_n || !enable) begin
            led <= 0;
            led_reg <= 24'h800000;
            direction <= 1'b0;
        end else
            case (direction)
                1'b0:
                    if (led_reg != 24'd1) begin
                        led_reg <= led_reg >> 1'b1;
                        led     <= led_reg >> 1'b1;
                    end else direction <= 1'b1;
                1'b1:
                    if (led != 24'h800000) begin
                        led_reg <= led_reg << 1'b1;
                        led     <= led_reg << 1'b1;
                    end else direction <= 1'b0;
            endcase
endmodule
