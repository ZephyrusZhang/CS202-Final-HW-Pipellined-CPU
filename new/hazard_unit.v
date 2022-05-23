`include "definitions.v"
`timescale 1ns / 1ps

/*
this module handles hazards and interrupts 
 */

module data_mem (
    input clk, rst_n,

    input uart_complete,                                        // from uart_unit (upg_done_i)

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
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_reg_dest_idx,   // from ex_mem_reg (index of destination resgiter)

    input      [`ISA_WIDTH - 1:0] pc,                           // from instruction_mem 

    input      cpu_pause,                                       // from keypad_unit
    
    output reg [1:0] hazard_control [`STAGE_CNT - 1:0]          // hazard control signal for each stage register
    output reg [1:0] cpu_state,                                 // for vga_unit (the state the CPU is in)
    output reg [2:0] issue_type                                 // for vga_unit (both hazard and interrupt)
    );

    wire reg_1_valid = ~(j_instruction | jal_instruction);
    wire reg_2_valid = r_type_instruction | store_instruction | branch_instruction;

    wire mem_conflict = mem_reg_write_enable &                                  // wirte enabled
                        ((reg_1_valid & id_reg_1_idx == mem_reg_dest_idx) |     // valid and conflict
                         (reg_2_valid & id_reg_2_idx == mem_reg_dest_idx));     // valid and conflict
    wire ex_conflict  = ex_reg_write_enable  &                                  // wirte enabled
                        ((reg_1_valid & id_reg_1_idx == ex_reg_dest_idx)  |     // valid and conflict
                         (reg_2_valid & id_reg_2_idx == ex_reg_dest_idx));      // valid and conflict
    
    wire data_hazard    = (branch_instruction & (ex_conflict | mem_conflict)) |     // data hazard when branch depends on data from previous stages 
                          (ex_mem_read_enable & ex_conflict);                       // data hazard when alu depends on data from memory at the next stage
    wire uart_hazard    = `PC_MAX_VALUE < pc;                                       // the next instruction is not in instruction memory
    wire pause_hazard   = cpu_pause;

    always @(*) begin
        
    end

    always @(negedge clk) begin
        if (~rst_n) begin
            hazard_unit_state <= IDLE;
            issue_type        <= NONE;
            for (i = 0; i < `STAGE_CNT; i = i + 1) hazard_control[i] <= `NORMAL;
        end else begin
            case (hazard_unit_state) 
                `IDLE: 
                    hazard_unit_state <= EXECUTE;
                `EXECUTE: begin
                    casex ({data_hazard, pause_hazard, uart_hazard})
                        4'b1xx: begin // data hazard will hold all stages hence covers the other hazards
                            cpu_state <= `DATA;
                            hazard_control[`HAZD_IF_IDX] <= `HOLD;  // if stage will not be a bubble
                            harard_control[`HAZD_ID_IDX] <= `HOLD;  // id stage will not be a bubble
                            harard_control[`HAZD_EX_IDX] <= `NO_OP; // ex stage will be a bubble (the instruction in ex will enter wb by then)
                        end
                        4'b01x: begin // no data hazard but the user paused the CPU
                            
                        end
                        4'b001: begin // the user did not pause the CPU
                            
                        end
                        default: begin
                            cpu_state <= `NONE;
                            for (i = 0; i < `STAGE_CNT; i = i + 1) hazard_control[i] <= `NORMAL;
                        end
                    endcase
                    if (hazard)
                end
                `HAZARD:     
                `INTERRUPT:  
                default: 
            endcase   
        end
    end
endmodule