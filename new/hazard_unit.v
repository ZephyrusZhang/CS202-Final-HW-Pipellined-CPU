`include "definitions.v"
`timescale 1ns / 1ps

/*
this module handles hazards and interrupts 
 */

module data_mem (
    input clk, rst_n,

    input      uart_complete,                                   // from uart_unit (upg_done_i)
    output reg uart_disable,                                    // for (1) uart_unit (upg_rst_i)
                                                                //     (2) instruction_mem (switch to uart write mode)
                                                                //     (3) data_mem (switch to uart write mode)

    input      reg_1_valid,                                     // from signal_mux (whether register 1 is valid)
    input      reg_2_valid,                                     // from signal_mux (whether register 2 is valid)
    input      branch_instruction,                              // from control_unit (whether it is a branch instruction)

    input      ex_mem_read_enable,                              // from id_ex_reg (instruction needs to read from memory)
    input      ex_reg_write_enable,                             // from id_ex_reg (instruction needs write to register)
    input      ex_no_op,                                        // from id_ex_reg (the ex stage is a bubble)
    input      mem_reg_write_enable,                            // from ex_mem_reg (instruction needs write to register)
    input      mem_no_op,                                       // from ex_mem_reg (the mem stage is a bubble)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_1_idx,       // from if_id_reg (index of first source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_2_idx,       // from if_id_reg (index of second source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_dest_idx,    // from if_id_reg (index of destination resgiter)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx,    // from id_ex_reg (index of destination resgiter)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_reg_dest_idx,   // from ex_mem_reg (index of destination resgiter)

    input      [`ISA_WIDTH - 1:0] pc_next,                      // from instruction_mem 

    input      input_enable,                                    // from data_mem (the keypad input is needed)
    input      input_complete,                                  // from keypad_unit (user pressed enter)
    input      cpu_pause,                                       // from keypad_unit (user pressed pause)

    output reg pc_reset,                                        // for instruction_mem (reset the pc to 0)
    output reg [1:0] hazard_control [`STAGE_CNT - 1:0]          // hazard control signal for each stage register
    output reg [1:0] cpu_state,                                 // for vga_unit (the state the CPU is in)
    output reg [2:0] issue_type                                 // for vga_unit (both hazard and interrupt)
    );

    wire mem_conflict = mem_reg_write_enable & ~mem_no_op                       // wirte enabled and operational
                        ((reg_1_valid & id_reg_1_idx == mem_reg_dest_idx) |     // valid and conflict
                         (reg_2_valid & id_reg_2_idx == mem_reg_dest_idx));     // valid and conflict
    wire ex_conflict  = ex_reg_write_enable  & ~ex_no_op                        // wirte enabled and operational
                        ((reg_1_valid & id_reg_1_idx == ex_reg_dest_idx)  |     // valid and conflict
                         (reg_2_valid & id_reg_2_idx == ex_reg_dest_idx));      // valid and conflict
    
    wire data_hazard    = (branch_instruction & (ex_conflict | mem_conflict)) |     // data hazard when branch depends on data from previous stages 
                          (ex_mem_read_enable & ex_conflict);                       // data hazard when alu depends on data from memory at the next stage
    wire uart_hazard    = `PC_MAX_VALUE < pc_next;                                  // next instruction not in instruction memory
    
    wire data_resolved    = issue_type == `DATA   & ~data_hazard;
    wire uart_resolved    = issue_type == `UART   & uart_complete;
    wire pause_resolved   = issue_type == `PAUSE  & ~cpu_pause & uart_complete;

    always @(negedge clk, negedge rst_n) begin
        if (~rst_n) begin
            cpu_state    <= `IDLE;
            issue_type   <= `NONE;
            pc_reset     <= 1'b0;
            uart_disable <= 1'b1;
            for (i = 0; i < `STAGE_CNT; i = i + 1) 
                hazard_control[i] <= `NORMAL;
        end else begin
            case (cpu_state) 
                `EXECUTE: begin
                    casex ({data_hazard, cpu_pause, uart_hazard, input_enable})
                        // data hazard will hold all stages hence covers the other hazards
                        4'b1xxx: begin
                            issue_type <= `DATA;
                            cpu_state  <= `HAZARD;
                            hazard_control[`HAZD_IF_IDX] <= `HOLD;  // if stage will not be a bubble
                            harard_control[`HAZD_ID_IDX] <= `HOLD;  // id stage will not be a bubble
                            harard_control[`HAZD_EX_IDX] <= `NO_OP; // ex stage will be a bubble (the instruction in ex will enter wb by then)
                        end
                        // the user paused the CPU, the user can do UART rewrite during this period
                        4'b01xx: begin
                            issue_type   <= `PAUSE;
                            cpu_state    <= `HAZARD;
                            uart_disable <= 1'b0;
                            harard_control[`HAZD_IF_IDX] <= `NO_OP; // start pumping no_op signals into the pipeline
                        end
                        // the user did not pause the CPU but the pc overflowed, the CPU will automatically resume upon UART completion
                        4'b001x: begin
                            issue_type   <= `UART;
                            cpu_state    <= `HAZARD;
                            uart_disable <= 1'b0;
                            harard_control[`HAZD_IF_IDX] <= `NO_OP;
                        end
                        // CPU waits for the user's keypad input
                        4'b0001: begin
                            issue_type   <= `KEYPAD;
                            cpu_state    <= `INTERRUPT;
                            for (i = 0; i < `STAGE_CNT; i = i + 1) 
                                hazard_control[i] <= `NO_OP;
                        end
                        default:
                            issue_type   <= issue_type; // prevent auto latches
                    endcase
                end
                `HAZARD: begin
                    case ({data_resolved, pause_resolved | uart_resolved})
                        2'b10  : begin
                            issue_type   <= `NONE;
                            cpu_state    <= `EXECUTE;
                            hazard_control[`HAZD_IF_IDX] <= `NORMAL;
                            harard_control[`HAZD_ID_IDX] <= `NORMAL;
                            harard_control[`HAZD_EX_IDX] <= `NORMAL;
                        end
                        2'b01  : begin
                            issue_type   <= `NONE;
                            cpu_state    <= `EXECUTE;
                            uart_disable <= 1;
                            harard_control[`HAZD_IF_IDX] <= `NORMAL;
                        end
                        default: 
                            if (issue_type == `UART & cpu_pause) 
                                issue_type <= `PAUSE;       // pause after pc overflow which then the CPU must wait for the user to resume it
                            else 
                                issue_type <= issue_type;   // prevent auto latches
                    endcase
                end   
                `INTERRUPT: begin
                    if (input_complete) begin
                        issue_type <= `NONE;
                        cpu_state  <= `EXECUTE;
                        for (i = 0; i < `STAGE_CNT; i = i + 1) 
                            hazard_control[i] <= `NORMAL;
                    end else 
                        issue_type <= issue_type; // prevent auto latches
                end
                default: // this is for `IDLE state, preventing auto latches
                    cpu_state <= `EXECUTE;
            endcase   
        end
    end
endmodule