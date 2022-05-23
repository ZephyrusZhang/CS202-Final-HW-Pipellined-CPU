`include "definitions.v"
`timescale 1ns / 1ps

/*
this module handles hazards and interrupts 
 */

module data_mem (
    input clk, rst_n,

    input uart_complete,                                        // from uart_unit (upg_done_i)
    output reg [1:0] hazard_control [4:0]                       // hazard control signal for each stage register
    output reg [1:0] cpu_state,                                 // for vga_unit (the state the CPU is in)
    output reg [2:0] issue_type,                                // for vga_unit (both hazard and interrupt)

    input      i_type_instruction,                              // from control_unit (whether it is a I type instruction)
    input      r_type_instruction,                              // from control_unit (whether it is a R type instruction)
    input      j_instruction,                                   // from control_unit (whether it is a jump instruction)
    input      jr_instruction,                                  // from control_unit (whether it is a jr instruction)
    input      jal_instruction,                                 // from control_unit (whether it is a jal insutrction)
    input      branch_instruction,                              // from control_unit (whether it is a branch instruction)
    input      store_instruction,                               // from control_unit (whether it is a strore instruction)

    input      condition_satisfied,                             // from condition_check (whether the branch condition is met)

    input      ex_mem_read_enable,                              // from control_unit (instruction needs to read from memory)
    input      ex_reg_write_enable,                             // from control_unit (instruction needs write to register)
    input      mem_reg_write_enable,                            // from control_unit (instruction needs write to register)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_1_idx,       // from if_id_reg (index of first source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_2_idx,       // from if_id_reg (index of second source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_dest_idx,    // from if_id_reg (index of destination resgiter)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx,    // from id_ex_reg (index of destination resgiter)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_reg_dest_idx    // from ex_mem_reg (index of destination resgiter)
    );

    wire reg_1_valid = ~(j_instruction | jal_instruction);
    wire reg_2_valid = r_type_instruction | i_type_abnormal;

    wire mem_hazard = mem_reg_write_enable & ((reg_1_valid & id_reg_1_idx == mem_reg_dest_idx) | (reg_2_valid & id_reg_2_idx == mem_reg_dest_idx));
    wire ex_hazard  = ex_reg_write_enable  & ((reg_1_valid & id_reg_1_idx == ex_reg_dest_idx)  | (reg_2_valid & id_reg_2_idx == ex_reg_dest_idx));
    wire hazard     = ex_hazard | mem_hazard;

    always (negedge clk) {
        if (~rst_n) begin
            hazard_unit_state <= IDLE;
            issue_type        <= NONE;
            for (i = 0; i < `STAGE_CNT; i = i + 1)
                hazard_control[i] <= 0;
        end else begin
            case (hazard_unit_state) 
                IDLE: 
                    hazard_unit_state <= EXECUTE;
                EXECUTE: begin
                    hazard_detected = (branch_instruction & hazard) | (mem_read_enable & mem_hazard);
                end
                HAZARD:     
                INTERRUPT:  
                default: 
            endcase   
        end
    }
endmodule