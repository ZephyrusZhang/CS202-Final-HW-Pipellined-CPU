`include "definitions.v"
`timescale 1ns / 1ps

module top
       #(parameter ROM_DEPTH = `DEFAULT_ROM_DEPTH)(
           input wire clk, rst_n,
           input wire [3:0] row_in,

           output reg [3:0] col_out
           // output reg [7:0] led signal
           // vga signal

       );




//// wire list

//--------------------------------stage-if------------------------------------//
wire [`ISA_WIDTH - 1:0] if_pc;                       // from instruction_mem (pc + 4)
wire  if_no_op;                                      // for if_id_reg (stop id operations)
wire [`ISA_WIDTH - 1:0] if_instruction;             // from instruction_mem (the current instruction)
//--------------------------------if_id_reg-----------------------------------//

wire [`ISA_WIDTH - 1:0] id_pc;                        // for id_ex_reg (to store into 31st register)
wire id_no_op;                                        // for general_reg (stop opeartions)
wire [`ISA_WIDTH - 1:0] id_instruction;               // for control_unit (the current instruction)
//--------------------------------stage-id------------------------------------//


wire  [`REG_FILE_ADDR_WIDTH - 1 : 0]    read_reg_addr_1, read_reg_addr_2, write_reg_addr;  //from register_file
wire  [`ISA_WIDTH - 1 : 0]              write_data;                                        //from register_file
wire                                    write_en;                                          //from register_file
wire                                    wb_no_op;                                //from register_file
wire  [`ISA_WIDTH - 1 : 0]              read_data_1, read_data_2;                          //from register_file

wire  pc_offset;                                            // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_offset_value;                   // from signal_mux (mux_operand_2)
wire  pc_overload;                                          // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_overload_value;                 // from signal_mux (pc_overload_value)

wire  i_type_instruction;                                    // from control_unit (whether it is a I type instruction)
wire  r_type_instruction;                                    // from control_unit (whether it is a R type instruction)
wire  j_instruction;                                         // from control_unit (whether it is a jump instruction)
wire  jr_instruction;                                        // from control_unit (whether it is a jr instruction)
wire  jal_instruction;                                       // from control_unit (whether it is a jal insutrction)
wire  branch_instruction;                                    // from control_unit (whether it is a branch instruction)
wire  store_instruction;                                     // from control_unit (whether it is a strore instruction)

wire  condition_type;                                        //from condition_check
wire  condition_satisfied;                                    //from condition_check

//-------------------------------------------------------------------------------//


//--------------------------------id_exe_reg------------------------------------//


//-------------------------------------------------------------------------------//


//--------------------------------stage-exe------------------------------------//



//-------------------------------------------------------------------------------//


//--------------------------------stage-mem------------------------------------//



//-------------------------------------------------------------------------------//


//--------------------------------stage-wb------------------------------------//



//-------------------------------------------------------------------------------//

//--------------------------------stage-register------------------------------------//

wire [`ISA_WIDTH - 1:0] pc;                   // for (1) hazard_unit (to detect UART hazard)
//     (2) if_id_reg (jal store into 31st register)

wire [`ISA_WIDTH - 1:0] instruction;          // for if_id_reg (the current instruction)
//-------------------------------------------------------------------------------//



//-------------------------------------I/O------------------------------------------//


wire   uart_disable;                            // from hazard_unit (whether reading from uart)
wire   uart_clk;                                // from uart_unit (upg_clk_i)
wire   uart_write_enable;                       // from uart_unit (upg_wen_i)
wire   [`ISA_WIDTH - 1:0] uart_data;            // from uart_unit (upg_dat_i)
wire   [ROM_DEPTH:0] uart_addr;                 // from uart_unit (upg_adr_i)



//-------------------------------------------------------------------------------//



//----------------------------------hazard-unit------------------------------------------//

wire  pc_reset;                                // from hazard_unit (reset pc when UART is completed)
wire  [1:0] hazard_control;                    // from hazard_unit [HAZD_HOLD_BIT] discard pc_next result
//                  [HAZD_if_no_op_BIT] pause if stage


//-------------------------------------------------------------------------------//






//// module list

//--------------------------------stage-if------------------------------------//

instruction_mem instruction_mem(
                    .clk(clk),
                    .rst_n(rst_n),
                    .uart_disable(uart_disable),
                    .uart_clk(uart_clk),
                    .uart_write_enable(uart_write_enable),
                    .uart_data(uart_data),
                    .uart_addr(uart_addr),
                    .pc_offset(pc_offset),
                    .pc_offset_value(pc_offset_value),
                    .pc_overload(pc_overload),
                    .pc_overload_value(pc_overload_value),
                    .pc_reset(pc_reset),
                    .hazard_control(hazard_control),

                    .if_no_op(if_no_op),
                    .if_pc(pc),             //?
                    .instruction(instruction)
                );

//-------------------------------------------------------------------------------//

//--------------------------------if-id-reg------------------------------------//

//--------------------------------stage-id------------------------------------//

register_file register_file(
                  .clk(clk),
                  .rst_n(rst_n),
                  .read_reg_addr_1(read_reg_addr_1),
                  .read_reg_addr_2(read_reg_addr_2),
                  .write_reg_addr(write_reg_addr),
                  .write_data(write_data),
                  .write_en(write_en),
                  .wb_no_op(wb_no_op),
                  .id_no_op(id_no_op),
                  .read_data_1(read_data_1),
                  .read_data_2(read_data_2)
              );

//-------------------------------------------------------------------------------//

endmodule
