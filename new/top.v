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


wire  [`REG_FILE_ADDR_WIDTH - 1 : 0]    read_reg_addr_1, read_reg_addr_2, write_reg_addr;  //decoding from pc
wire[`OP_CODE_WIDTH - 1 : 0]          opcode;
wire[`FUNC_CODE_WIDTH - 1 : 0]        func;

assign opcode = id_pc[31:26];
assign read_reg_addr_1 = id_pc[25:21];      //rs
assign read_reg_addr_2 = id_pc[20:16];      //rt
assign write_reg_addr = id_pc[15:11];       //rd
assign func = id_pc[5:0];                   //funct 
assign immediate = id_pc[15:0];             // address


wire  [`ISA_WIDTH - 1 : 0]              write_data;                              //from register_file
wire                                    write_en;                                //from register_file
wire                                    wb_no_op;                                //from register_file
wire  [`ISA_WIDTH - 1 : 0]              read_data_1, read_data_2;                //from register_file



wire [`ALU_CONTROL_WIDTH - 1:0]       alu_opcode;
wire [1:0]                            mem_control;
wire                                  wb_en;


wire  i_type_instruction;                                    // from control_unit (whether it is a I type instruction)
wire  r_type_instruction;                                    // from control_unit (whether it is a R type instruction)
wire  j_instruction;                                         // from control_unit (whether it is a jump instruction)
wire  jr_instruction;                                        // from control_unit (whether it is a jr instruction)
wire  jal_instruction;                                       // from control_unit (whether it is a jal insutrction)
wire  branch_instruction;                                    // from control_unit (whether it is a branch instruction)
wire  store_instruction;                                     // from control_unit (whether it is a strore instruction)
wire  condition_satisfied;                                   //from condition_chec
wire  pc_offset;                                            // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_offset_value;                   // from signal_mux (mux_operand_2)
wire  pc_overload;                                          // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_overload_value;                 // from signal_mux (pc_overload_value)




    
wire [`ISA_WIDTH - 1:0] id_reg_1;                     // from general_reg (first register's value)
wire [`ISA_WIDTH - 1:0] mux_operand_1;                // for id_ex_reg (to pass on to alu)
wire [`ISA_WIDTH - 1:0] id_reg_2;                     // from general_reg (second register's value)
wire [`ISA_WIDTH - 1:0] mux_operand_2;                // for (1) id_ex_reg (to pass on to alu)
                                                      //     (2) instruction_mem (pc_offset_value)
 
 
wire [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_1_idx;       // from if_id_reg (index of first source register)
wire [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_2_idx;       // from if_id_reg (index of second source register)
wire [`REG_FILE_ADDR_WIDTH - 1:0] id_reg_dest_idx;    // from if_id_reg (index of destination resgiter)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx;      // for id_ex_reg (to pass on to forwarding_unit)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx;      // for id_ex_reg (to pass on to forwarding_unit)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx;   // for id_ex_reg
 
wire reg_1_valid;                                     // for hazard_unit
wire reg_2_valid;                                     // for hazard_unit
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
if_id_reg if_id_reg(
              .clk(clk),
              .rst_n(rst_n),
              .hazard_control(hazard_control),
              .if_no_op(if_no_op),
              .id_no_op(id_no_op),
              .if_pc(if_pc),
              .id_pc(id_pc),
              .if_instruction(if_instruction),
              .id_instruction(id_instruction),

              .pc_offset(pc_offset),
              .pc_overload(pc_overload)

          );
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

condition_check condition_check(
                    .branch_instruction(condition_type),
                    .read_data_1(read_data_1),
                    .read_data_2(read_data_2),
                    .condition_satisfied(condition_satisfied)
                );



control control(
            .opcode(opcode),
            .func(func),

            .alu_opcode(alu_opcode),
            .mem_control(mem_control),
            .i_type_instruction(i_type_instruction),
            .r_type_instruction(r_type_instruction),
            .j_instruction(j_instruction),
            .jr_instruction(jr_instruction),
            .jal_instruction(jal_instruction),
            .branch_instruction(branch_instruction),
            .store_instruction(store_instruction),
            .wb_en(wb_en)
        );

//-------------------------------------------------------------------------------//

endmodule
