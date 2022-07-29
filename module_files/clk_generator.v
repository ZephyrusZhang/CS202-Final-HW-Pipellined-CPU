`timescale 1ns / 1ps
`define DEFAULT_PERIOD 10_0000

module clk_generator #(parameter 
    PERIOD = `DEFAULT_PERIOD
    )(
    input wire clk, rst_n,
    output wire clk_out
    );

    localparam HALF_PERIOD = (PERIOD >> 1) - 1;

    reg [31:0] cnt;
    reg posedge_clk, negedge_clk;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            cnt <= 32'b0;
            posedge_clk <= 1'b0;
        end else begin
            case (PERIOD[0])
            1'b0:
                if (cnt == HALF_PERIOD) begin
                    posedge_clk <= ~posedge_clk;
                    cnt <= 32'b0;
                end else cnt <= cnt + 1'b1;
            1'b1:
                case (posedge_clk)
                1'b0:
                    if (cnt == HALF_PERIOD + 1) begin
                        posedge_clk <= ~posedge_clk;
                        cnt <= 32'b0;
                    end else cnt <= cnt + 1'b1;
                1'b1:
                    if (cnt == HALF_PERIOD) begin
                        posedge_clk <= ~posedge_clk;
                        cnt <= 32'b0;
                    end else cnt <= cnt + 1'b1;
                endcase
            endcase
        end    
    end

    always @(negedge clk) begin
        if (~rst_n || PERIOD[0] == 0) begin
            negedge_clk <= 1'b0;
        end else negedge_clk <= posedge_clk;
    end

    assign clk_out = (PERIOD != 1) ? (posedge_clk | negedge_clk) : clk;

endmodule
