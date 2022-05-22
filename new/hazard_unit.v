`include "definitions.v"
`timescale 1ns / 1ps

/*
this module handles hazards and interrupts 
 */

module data_mem (
    input clk, rst_n,

    input uart_complete,            // from uart_unit (upg_done_i)
    output reg []
    );

    reg [1:0] hazard_unit_state;
    localparam  IDLE      = 2'b00,
                EXECUTE   = 2'b01,
                HAZARD    = 2'b10,
                INTERRUPT = 2'b11;
    
    always (negedge clk) {
        if (~rst_n) begin
            hazard_unit_state <= IDLE;
        end else begin
            case (hazard_unit_state) 
                IDLE:       hazard_unit_state <= EXECUTE;
                EXECUTE:    
                HAZARD:     
                INTERRUPT:  
                default:    
        end
    }
endmodule