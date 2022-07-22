`include "definitions.v"
`timescale 1ns / 1ps

/*
this module handles hazards and interrupts 
 */

module hazard_unit (
    input clk, rst_n,

    input      uart_complete,                                   // from uart_unit (upg_done_i)
    input      uart_write_enable,                               // from uart_unit (upg_wen_o)
    output reg uart_disable,                                    // for (1) uart_unit (upg_rst_i)
                                                                //     (2) instruction_mem (switch to uart write mode)
                                                                //     (3) data_mem (switch to uart write mode)

    input      branch_instruction,                              // from control_unit (whether it is a branch instruction)
    input      store_instruction,                               // from control_unit (whether it is a strore instruction)

    input      if_no_op,                                        // from instruction_mem  (the if stage is a bubble)
    input      id_no_op,                                        // from if_id_reg  (the id stage is a bubble)
    input      ex_mem_read_enable,                              // from id_ex_reg  (instruction needs to read from memory)
    input      ex_reg_write_enable,                             // from id_ex_reg  (instruction needs write to register)
    input      ex_no_op,                                        // from id_ex_reg  (the ex stage is a bubble)
    input      mem_reg_write_enable,                            // from ex_mem_reg (instruction needs write to register)
    input      mem_no_op,                                       // from ex_mem_reg (the mem stage is a bubble)

    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_1_idx,       // from signal_mux (index of first source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_2_idx,       // from signal_mux (index of second source register)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_dest_idx,    // from signal_mux (index of the destination register or the source for store)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx,    // from id_ex_reg  (index of destination resgiter)
    input      [`REG_FILE_ADDR_WIDTH - 1:0] mem_reg_dest_idx,   // from ex_mem_reg (index of destination resgiter)

    input      [`ISA_WIDTH - 1:0] pc,                           // from instruction_mem (the value of pc)

    input      input_enable,                                    // from data_mem (the keypad input is needed)
    input      input_complete,                                  // from input_unit (user pressed enter)
    input      cpu_pause,                                       // from input_unit (user pressed pause)
    output reg ignore_pause,                                    // for input_unit (ignore the user resume action during uart transmission)

    output reg pc_reset,                                        // for instruction_mem (reset the pc to 0)
    
    output reg [`HAZD_CTL_WIDTH - 1:0] if_hazard_control,       // for each stage register (hazard control signal)
                                       id_hazard_control,
                                       ex_hazard_control,
                                       mem_hazard_control,
                                       wb_hazard_control,       
    output reg ignore_no_op,                                    // for each stage register (ignore previous no_op during recovery from interrupt)

    output reg [`ISSUE_TYPE_WIDTH - 1:0] issue_type             // for vga_unit (both hazard and interrupt)
    );
    
    // the state CPU is in
    localparam  STATE_WIDTH = 2,
                IDLE        = 2'b00,
                EXECUTE     = 2'b01,
                HAZARD      = 2'b10,
                INTERRUPT   = 2'b11;
    reg [STATE_WIDTH - 1:0] cpu_state;    

    reg [(`HAZD_CTL_WIDTH * `STAGE_CNT) - 1:0] control_snapshot;

    wire reg_1_valid  = (id_reg_1_idx != 0);                                            // whether register 1 is valid
    wire reg_2_valid  = (id_reg_2_idx != 0);                                            // whether register 2 is valid

    wire mem_conflict = mem_reg_write_enable & ~mem_no_op &                             // wirte enabled and operational
                        ((reg_1_valid & (id_reg_1_idx == mem_reg_dest_idx)) |           // valid and conflict
                         (reg_2_valid & (id_reg_2_idx == mem_reg_dest_idx)));           // valid and conflict
    wire ex_conflict  = ex_reg_write_enable  & ~ex_no_op  &                             // wirte enabled and operational
                        ((reg_1_valid & (id_reg_1_idx == ex_reg_dest_idx )) |           // valid and conflict
                         (reg_2_valid & (id_reg_2_idx == ex_reg_dest_idx )) |           // valid and conflict
                         (store_instruction  & id_reg_dest_idx == ex_reg_dest_idx));    // the value to store is the previous result
    
    wire data_hazard  = (branch_instruction  & (ex_conflict | mem_conflict)) |          // data hazard when branch depends on data from previous stages 
                        (ex_mem_read_enable  & ex_conflict);                            // data hazard when alu depends on data from memory at the next stage
    wire fallthrough  = `PC_MAX_VALUE < pc   & ~if_no_op;                               // uart hazard when next instruction is valid and not in memory 


    always @(negedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                control_snapshot,
                pc_reset,
                ignore_no_op,
                ignore_pause
            }                  <= 0;
            uart_disable       <= 1'b1;

            issue_type         <= `ISSUE_NONE;
            cpu_state          <= IDLE;

            if_hazard_control  <= `HAZD_CTL_NORMAL;
            id_hazard_control  <= `HAZD_CTL_NORMAL;
            ex_hazard_control  <= `HAZD_CTL_NORMAL;
            mem_hazard_control <= `HAZD_CTL_NORMAL;
            wb_hazard_control  <= `HAZD_CTL_NORMAL;
        end else begin
            case (cpu_state) 
                EXECUTE: 
                    casex ({input_enable, data_hazard, cpu_pause, fallthrough})
                        /* CPU waits for the user's keypad input, will hold all stages hence covers the other hazards */
                        4'b1xxx: begin
                            issue_type         <= `ISSUE_KEYPAD;
                            cpu_state          <= INTERRUPT;
                            
                            control_snapshot   <= {
                                                      `HAZD_CTL_NORMAL,
                                                      if_no_op               ? `HAZD_CTL_NO_OP : (
                                                                 data_hazard ? `HAZD_CTL_RETRY : `HAZD_CTL_NORMAL),
                                                      id_no_op | data_hazard ? `HAZD_CTL_NO_OP : `HAZD_CTL_NORMAL,
                                                      ex_no_op               ? `HAZD_CTL_NO_OP : `HAZD_CTL_NORMAL,
                                                      mem_no_op              ? `HAZD_CTL_NO_OP : `HAZD_CTL_NORMAL
                                                  }; // resumes while dealing with the data hazard
                            
                            if_hazard_control  <= `HAZD_CTL_NO_OP; // stop all stages
                            id_hazard_control  <= `HAZD_CTL_NO_OP;
                            ex_hazard_control  <= `HAZD_CTL_NO_OP;
                            mem_hazard_control <= `HAZD_CTL_NO_OP;
                            wb_hazard_control  <= `HAZD_CTL_NO_OP;
                        end
                        /* data hazard preceeds pause as pause will leave the data hazard undealt with */
                        4'b01xx: begin
                            issue_type         <= `ISSUE_DATA;
                            cpu_state          <= HAZARD;

                            if_hazard_control  <= `HAZD_CTL_RETRY; // retry if stage
                            id_hazard_control  <= `HAZD_CTL_RETRY; // retry id stage 
                            ex_hazard_control  <= `HAZD_CTL_NO_OP; // the ex stage will be a bubble
                        end
                        /* the user paused the CPU, the user can do UART rewrite during this period */
                        4'b001x: begin
                            issue_type         <= `ISSUE_PAUSE;
                            cpu_state          <= HAZARD;
                            uart_disable       <= 1'b0;
                            
                            if_hazard_control  <= `HAZD_CTL_NO_OP; // start pumping no_op signals into the pipeline (pc will still react to pc updates)
                        end
                        /* the user did not pause the CPU but the pc overflowed, the CPU will await user resumption upon UART completion */
                        4'b0001: begin
                            issue_type         <= `ISSUE_FALLTHROUGH;
                            cpu_state          <= HAZARD;
                            uart_disable       <= 1'b0;

                            if_hazard_control  <= `HAZD_CTL_NO_OP; // start pumping no_op signals into the pipeline (pc will still react to pc updates)
                        end
                        default: 
                            cpu_state <= cpu_state; // prevent auto latches
                    endcase
                HAZARD: 
                    case (issue_type)
                        `ISSUE_NONE,
                        `ISSUE_DATA       : begin
                            ignore_no_op <= 1'b0; // for resuming from INTERRUPT

                            casex ({input_enable, data_hazard, cpu_pause, fallthrough})
                                /* CPU waits for the user's keypad input, will hold all stages hence covers the other hazards */
                                4'b1xxx: begin
                                    issue_type         <= `ISSUE_KEYPAD;
                                    cpu_state          <= INTERRUPT;
                                    
                                    control_snapshot   <= {
                                                              `HAZD_CTL_NORMAL,
                                                              if_no_op               ? `HAZD_CTL_NO_OP : (
                                                                         data_hazard ? `HAZD_CTL_RETRY : `HAZD_CTL_NORMAL),
                                                              id_no_op | data_hazard ? `HAZD_CTL_NO_OP : `HAZD_CTL_NORMAL,
                                                              ex_no_op               ? `HAZD_CTL_NO_OP : `HAZD_CTL_NORMAL,
                                                              mem_no_op              ? `HAZD_CTL_NO_OP : `HAZD_CTL_NORMAL
                                                          }; // resumes while dealing with the data hazard
                                    
                                    if_hazard_control  <= `HAZD_CTL_NO_OP; // stop all stages
                                    id_hazard_control  <= `HAZD_CTL_NO_OP;
                                    ex_hazard_control  <= `HAZD_CTL_NO_OP;
                                    mem_hazard_control <= `HAZD_CTL_NO_OP;
                                    wb_hazard_control  <= `HAZD_CTL_NO_OP;
                                end
                                /* data hazard preceeds pause as pause will leave the data hazard undealt with */
                                4'b01xx: begin
                                    issue_type         <= `ISSUE_DATA;

                                    if_hazard_control  <= `HAZD_CTL_RETRY;  // retry if stage
                                    id_hazard_control  <= `HAZD_CTL_RETRY;  // retry id stage 
                                    ex_hazard_control  <= `HAZD_CTL_NO_OP;  // the ex stage will be a bubble
                                    mem_hazard_control <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    wb_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                end
                                /* the user paused the CPU, the user can do UART rewrite during this period */
                                4'b001x: begin
                                    issue_type         <= `ISSUE_PAUSE;
                                    uart_disable       <= 1'b0;

                                    if_hazard_control  <= `HAZD_CTL_NO_OP;  // start pumping no_op signals into the pipeline (pc will still react to pc updates)
                                    id_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    ex_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    mem_hazard_control <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    wb_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                end
                                /* the user did not pause the CPU but the pc overflowed, the CPU will await user resumption upon UART completion */
                                4'b0001: begin
                                    issue_type         <= `ISSUE_FALLTHROUGH;
                                    uart_disable       <= 1'b0;

                                    if_hazard_control  <= `HAZD_CTL_NO_OP;  // start pumping no_op signals into the pipeline (pc will still react to pc updates)
                                    id_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    ex_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    mem_hazard_control <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                    wb_hazard_control  <= `HAZD_CTL_NORMAL; // cleanse the control signal from INTERRUPT
                                end
                                /* data hazard have been solved, the CPU can resume without any problems, also used before resuming from INTERRUPT */
                                default: begin
                                    issue_type         <= `ISSUE_NONE;
                                    cpu_state          <= EXECUTE;

                                    if_hazard_control  <= `HAZD_CTL_NORMAL;
                                    id_hazard_control  <= `HAZD_CTL_NORMAL;
                                    ex_hazard_control  <= `HAZD_CTL_NORMAL;
                                    mem_hazard_control <= `HAZD_CTL_NORMAL;
                                    wb_hazard_control  <= `HAZD_CTL_NORMAL;
                                end
                            endcase
                        end
                        `ISSUE_FALLTHROUGH: 
                            casex ({~fallthrough, uart_write_enable, cpu_pause})
                                /* jump instruction is the last instruction and the control hazard have been resolved */
                                3'b1xx : begin
                                    issue_type        <= `ISSUE_NONE;
                                    cpu_state         <= EXECUTE;

                                    uart_disable      <= 1'b1;
                                    if_hazard_control <= `HAZD_CTL_NORMAL; // resuming the entire cpu from the next instruction
                                end
                                3'b01x : begin
                                    issue_type        <= `ISSUE_UART;
                                    ignore_pause      <= 1'b1;
                                end
                                3'b001 : begin
                                    issue_type        <= `ISSUE_PAUSE;
                                    pc_reset          <= 1'b1; // resets the pc when user pressed pause after a fallthrough
                                end
                                default: 
                                    cpu_state         <= cpu_state; // prevent auto latches
                            endcase
                        `ISSUE_PAUSE      : begin
                            pc_reset <= 1'b0;

                            if (uart_write_enable) begin
                                issue_type        <= `ISSUE_UART;
                                ignore_pause      <= 1'b1;
                            end else if (~cpu_pause) begin
                                issue_type        <= `ISSUE_NONE;
                                cpu_state         <= EXECUTE;
                                
                                uart_disable      <= 1'b1;
                                if_hazard_control <= `HAZD_CTL_NORMAL; // resuming the entire cpu from the next instruction
                            end else 
                                cpu_state         <= cpu_state;
                        end
                        `ISSUE_UART       : 
                            if (uart_complete) begin
                                issue_type   <= `ISSUE_PAUSE;
                                ignore_pause <= 1'b0;
                                pc_reset     <= 1'b1;
                            end else
                                cpu_state    <= cpu_state; // prevent auto latches
                        default           : 
                            cpu_state <= cpu_state; // prevent auto latches
                    endcase
                INTERRUPT: 
                    case (issue_type)
                        `ISSUE_KEYPAD: 
                            casex ({input_complete, cpu_pause})
                                2'b1x  : begin
                                    ignore_no_op <= 1'b1; // ignore no_op signals from previous stages and only comply to the snapshot

                                    issue_type   <= `ISSUE_NONE; // guarenteed as INTERRUPT only when there's no data hazards
                                    cpu_state    <= HAZARD; // hijacking the data hazard recovery step to reset all the control signals

                                    {
                                        if_hazard_control,
                                        id_hazard_control,
                                        ex_hazard_control,
                                        mem_hazard_control,
                                        wb_hazard_control
                                    }            <= control_snapshot; // resume with the snapshot taken before interrupt
                                end
                                2'b01  : begin
                                    issue_type   <= `ISSUE_PAUSE;
                                    uart_disable <= 1'b0;
                                end
                                default: 
                                    cpu_state    <= cpu_state; // prevent auto latches
                            endcase
                        `ISSUE_PAUSE : begin
                            pc_reset <= 1'b0;

                            if (uart_write_enable) begin
                                issue_type   <= `ISSUE_UART;
                                ignore_pause <= 1'b1;
                            end else if (~cpu_pause) begin
                                issue_type   <= `ISSUE_KEYPAD;
                                uart_disable <= 1'b1;
                            end else 
                                cpu_state    <= cpu_state; // prevent auto latches
                        end
                        `ISSUE_UART  : 
                            if (uart_complete) begin
                                issue_type   <= `ISSUE_PAUSE;
                                ignore_pause <= 1'b0;
                                pc_reset     <= 1'b1;
                            end else
                                cpu_state    <= cpu_state; // prevent auto latches
                        default      : 
                            cpu_state <= cpu_state; // prevent auto latches
                    endcase
                /* this is the IDLE state, gives one cycle for the IF stage to complete */
                default: 
                    cpu_state <= EXECUTE;
            endcase   
        end
    end
endmodule