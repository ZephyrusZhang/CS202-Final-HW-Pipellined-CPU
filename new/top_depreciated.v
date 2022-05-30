`include "definitions.v"
`timescale 1ns / 1ps

module top (
    input  clk_raw, rst_n,
    input  [7:0] switch_map,
    input  upg_rx,                                          // from uart_unit
    input  [3:0] row_in,
    output [3:0] col_out,
    output [6:0] seg_tube,   
    output [7:0] seg_enable  
    output [7:0] led_signal,
    output [`VGA_BIT_DEPTH - 1:0] vga_signal,
    output hsync, vsync,
    output utg_tx                                           // from uart_unit
    );
    
    // //--------------------------------stage-if------------------------------------//
    // wire [`ISA_WIDTH - 1:0] if_pc;                          // from instruction_mem (pc + 4)
    // wire if_no_op;                                          // for if_id_reg (stop id operations)
    // wire [`ISA_WIDTH - 1:0] if_instruction;                 // from instruction_mem (the current instruction)

    // //--------------------------------if_id_reg-----------------------------------//
    // wire [`ISA_WIDTH - 1:0] id_pc;                          // for id_ex_reg (to store into 31st register)
    // wire id_no_op;                                          // for general_reg (stop opeartions)
    // wire [`ISA_WIDTH - 1:0] id_instruction;                 // for control_unit (the current instruction)

    // //--------------------------------stage-id------------------------------------//
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] rs, rt, rd;           // decoding from pc
    // wire [`OP_CODE_WIDTH - 1:0] opcode;
    // wire [`ISA_WIDTH - 1:0] extend_result;

    // // op [31:26]
    // assign opcode = id_pc[`ISA_WIDTH-1:`ISA_WIDTH -`OP_CODE_WIDTH];
    // // rs [25:21]
    // assign rs = id_pc[`ISA_WIDTH - `OP_CODE_WIDTH - 1:`ISA_WIDTH - `OP_CODE_WIDTH - `REG_FILE_ADDR_WIDTH];
    // // rt [20:16]
    // assign rt = id_pc[`ISA_WIDTH - `OP_CODE_WIDTH - `REG_FILE_ADDR_WIDTH - 1:`ISA_WIDTH -`OP_CODE_WIDTH- 2 * `REG_FILE_ADDR_WIDTH];
    // // rd [15:11]
    // assign rd = id_pc[`ISA_WIDTH - `OP_CODE_WIDTH - (2 * `REG_FILE_ADDR_WIDTH) - 1:`ISA_WIDTH - `OP_CODE_WIDTH - (3 * `REG_FILE_ADDR_WIDTH)];

    // wire id_reg_write_enable;                           // for future register_file
    
    // wire [`ISA_WIDTH - 1:0] read_data_1, read_data_2;   // from register_file
    // wire [`ALU_CONTROL_WIDTH - 1:0] id_alu_opcode;      // for alu
    // wire [1:0] id_mem_control;                          // for data_mem

    // wire [`ISA_WIDTH - 1:0] mux_operand_1;              // for id_ex_reg (to pass on to alu)
    // wire [`ISA_WIDTH - 1:0] mux_operand_2;              // for (1) id_ex_reg (to pass on to alu)
    //                                                     //     (2) instruction_mem

    // wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx;    // for id_ex_reg (to pass on to forwarding_unit)
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx;    // for id_ex_reg (to pass on to forwarding_unit)
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx; // for id_ex_reg

    // wire reg_1_valid;                                   // for hazard_unit
    // wire reg_2_valid;                                   // for hazard_unit

    // //--------------------------------id_exe_reg------------------------------------//
    // wire ex_no_op;                                      // for alu (stop opeartions)
    // wire ex_reg_write_enable;                           // for ex_mem_reg
    // wire [1:0] ex_mem_control;                          // for ex_mem_reg
    // wire [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control;     // for alu
    // wire [`ISA_WIDTH - 1:0] ex_operand_1;               // for alu (first oprand for alu)
    // wire [`ISA_WIDTH - 1:0] ex_operand_2;               // for alu (second oprand for alu)
    // wire [`ISA_WIDTH - 1:0] ex_store_data;              // for ex_mem_reg (the data to be store into memory)
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_1_idx;     // for forwarding_unit
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_2_idx;     // for forwarding_unit
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx;  // for (1) forwarding_unit
    //                                                     //     (2) hazrad_unit
    //                                                     //     (3) ex_mem_reg

    // //--------------------------------stage-exe------------------------------------//
    // wire[`ISA_WIDTH - 1:0] ex_alu_output;               // from alu

    // //---------------------------------forwording----------------------------------//
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] dest_mem, dest_wb;
    // wire mem_wb_enable, wb_wb_enable;                   // write back enable from mem and wb stage
    // wire [`FORW_SEL_WIDTH - 1:0] val1_sel, val2_sel;    // for alu (operand selection)
    // wire [`FORW_SEL_WIDTH - 1:0] store_data_select;     // for ex_mem_reg (store data selection)

    // //---------------------------------ex_mem_reg----------------------------------//
    // wire mem_no_op;                                     // for alu (stop opeartions)
    // wire mem_reg_write_enable;                          // for mem_wb_reg
    // wire [1:0] mem_mem_control;                         // for (1) data_mem: both read and write
    //                                                     //     (2) mem_wb_reg: only read
    // wire [`ISA_WIDTH - 1:0] mem_alu_result;             // for (1) data_mem (the read or write address)
    //                                                     //     (2) mem_wb_reg (the result of alu)
    //                                                     //     (3) alu (forwarding)
    // wire [`ISA_WIDTH - 1:0] mem_store_data;             // for data_mem (the data to be stored)
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] mem_dest_reg_idx; // for (1) forwarding_unit
    //                                                     //     (2) harard_unit
    //                                                     //     (3) mem_wb_reg

    // //--------------------------------stage-mem------------------------------------//
    // wire [`ISA_WIDTH - 1:0] mem_read_data;              // for mem_wb_reg (the data read form memory)
    // wire input_enable;                                  // for (1) input_unit (signal the keypad and switch to start reading)
    //                                                     //     (2) hazard_unit (trigger keypad hazard)
    //                                                     //     (3) seven_seg_unit (display input value)
    // wire vga_write_enable;                              // for output_unit (write to vga display value register)
    // wire [`ISA_WIDTH - 1:0] vga_store_data;             // for output_unit (data to vga)

    // //---------------------------------mem-wb-reg--------------------------------//
    // wire wb_no_op;                                      // to register_file
    // wire wb_mem_read_enable;                            // for reg_write_select (to select data from memory)
    // wire [`ISA_WIDTH - 1:0] wb_alu_result;              // for (1) reg_write_select (result from alu)
    //                                                     //     (2) alu (forwarding)
    // wire [`ISA_WIDTH - 1:0] mem_mem_read_data;          // from data_mem (data read)
    // wire [`ISA_WIDTH - 1:0] wb_mem_read_data;           // for reg_write_select (data from memory)
    // wire [`REG_FILE_ADDR_WIDTH - 1:0] wb_dest_reg_idx;  // for (1) forwarding_unit

    // //--------------------------------stage-wb------------------------------------//
    // wire [`ISA_WIDTH - 1:0] wb_reg_write_data;          // from reg_write_select in wb stage
    // wire wb_reg_write_enable;                           // for register_file

    // //-------------------------------------uart_unit----------------------------------//
    // wire uart_disable;                                  // from hazard_unit (whether reading from uart)
    // wire uart_complete;                                 // from uart_unit (upg_done_i)
    // wire uart_write_enable;                             // from uart_unit (upg_wen_i)
    // wire [`ISA_WIDTH - 1:0] uart_data;                  // from uart_unit (upg_dat_i)
    // wire [`DEFAULT_RAM_DEPTH:0] uart_addr;              // from uart_unit (upg_adr_i)

    // //----------------------------------hazard-unit------------------------------------------//
    // wire pc_reset;                                      // for instruction_mem (reset the pc to 0)
    // wire [1:0] if_hazard_control,                       // hazard control signal for each stage register
    //            id_hazard_control,
    //            ex_hazard_control,
    //            mem_hazard_control,
    //            wb_hazard_control;
    // wire [2:0] issue_type;                              // for vga_unit (both hazard and interrupt)

    // //-------------------------------------input_unit----------------------------------------//
    // wire [`SWITCH_CNT - 1:0] switch_map;                // from toggle switches directly
    // wire input_complete;                                // for hazard_unit (user pressed enter)
    // wire [`ISA_WIDTH - 1:0] input_data;                 // for data_mem (data from user input)
    // wire switch_enable;                                 // for (1) seven_seg_unit (user is using switches)
    //                                                     //     (2) output_unit (display that input is switches)
    // wire cpu_pause;                                     // for hazard_unit (user pressed pause)

    // //-------------------------------------output_unit----------------------------------------//
    // wire [`COORDINATE_WIDTH - 1:0] x, y;                // from vga_unit

    // //-------------------------------------seven_seg_unit----------------------------------------//
    // wire  [`ISA_WIDTH - 1:0] display_value;             // from keypad_unit (value to be displayed)

    // //-------------------------------------keypad_unit_unit----------------------------------------//
    // wire [7:0] key_coord;                               // for input_unit 

    // //--------------------------------------------vga_unit----------------------------------------//
    // wire display_en;                                    // for input_unit

endmodule