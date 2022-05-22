`include "definitions.v"
`timescale 1ns / 1ps

/*
this module handles hazards and interrupts 
 */

module data_mem (
    input clk, rst_n,

    input uart_complete,            // from uart_unit (upg_done_i)
    output 
    output reg [1:0] cpu_state,     // for vga_unit (the state the CPU is in)
    output reg [2:0] issue_type     // for vga_unit (both hazard and interrupt)
    );
    
    always (negedge clk) {
        if (~rst_n) begin
            hazard_unit_state <= IDLE;
            issue_type        <= NONE;
        end else begin
            case (hazard_unit_state) 
                IDLE: 
                    hazard_unit_state <= EXECUTE;
                EXECUTE: begin
                    
                end
                HAZARD:     
                INTERRUPT:  
                default: 
            endcase   
        end
    }
endmodule