`include "definitions.v"
`timescale 1ns / 1ps



module top
       #(parameter ROM_DEPTH = `DEFAULT_ROM_DEPTH)(
           input wire clk, rst_n,
           input wire [3:0] row_in,

           output reg [3:0] col_out,
           // output reg [7:0] led signal
           // vga signal
           output reg  [6:0] seg_tube,                              // control signal for tube segments
           output reg [7:0] seg_enable,                               // control signal for tube positions
           output reg[`VGA_BIT_DEPTH - 1:0] vga_rgb           // VGA display signal
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
wire[`REG_FILE_ADDR_WIDTH - 1 : 0]     read_reg_addr_1, read_reg_addr_2, write_reg_addr;  //decoding from pc
wire[`OP_CODE_WIDTH - 1 : 0]           opcode;
wire[`FUNC_CODE_WIDTH - 1 : 0]         func;
wire[`IMMEDIATE_WIDTH -1 :0 ]          immediate;
wire[`ISA_WIDTH-1 : 0]                 extend_result;


assign opcode = id_pc[`ISA_WIDTH-1:`ISA_WIDTH -`OP_CODE_WIDTH];    //op(31:26)
assign read_reg_addr_1 = id_pc[`ISA_WIDTH -`OP_CODE_WIDTH -1:`ISA_WIDTH -`OP_CODE_WIDTH-`REG_FILE_ADDR_WIDTH]; //rs (25:21)
assign read_reg_addr_2 = id_pc[`ISA_WIDTH -`OP_CODE_WIDTH-`REG_FILE_ADDR_WIDTH - 1:`ISA_WIDTH -`OP_CODE_WIDTH- 2 * `REG_FILE_ADDR_WIDTH];                             //rt (20:16)
assign write_reg_addr = id_pc[`ISA_WIDTH -`OP_CODE_WIDTH- 2 * `REG_FILE_ADDR_WIDTH - 1:`ISA_WIDTH -`OP_CODE_WIDTH-3 * `REG_FILE_ADDR_WIDTH];                       //rd
assign func = id_pc[`FUNC_CODE_WIDTH-1:0];                                   //func
assign immediate = id_pc[`IMMEDIATE_WIDTH - 1:0];                             // address I type: low 16-bit


wire  [`ISA_WIDTH - 1 : 0]              read_data_1, read_data_2;                    //to register_file
wire [`ALU_CONTROL_WIDTH - 1:0]         alu_opcode;
wire [1:0]                              mem_control;


wire  i_type_instruction;                                    // from control_unit (whether it is a I type instruction)
wire  r_type_instruction;                                    // from control_unit (whether it is a R type instruction)
wire  j_instruction;                                         // from control_unit (whether it is a jump instruction)
wire  jr_instruction;                                        // from control_unit (whether it is a jr instruction)
wire  jal_instruction;                                       // from control_unit (whether it is a jal insutrction)
wire  branch_instruction;                                    // from control_unit (whether it is a branch instruction)
wire  store_instruction;                                     // from control_unit (whether it is a strore instruction)
wire  condition_satisfied;                                   //from condition_chec
wire  pc_offset;                                             // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_offset_value;                    // from signal_mux (mux_operand_2)
wire  pc_overload;                                           // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_overload_value;                  // from signal_mux (pc_overload_value)



wire [`ISA_WIDTH - 1:0] mux_operand_1;                      // for id_ex_reg (to pass on to alu)
wire [`ISA_WIDTH - 1:0] mux_operand_2;                      // for (1) id_ex_reg (to pass on to alu)

wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx;            // for id_ex_reg (to pass on to forwarding_unit)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx;            // for id_ex_reg (to pass on to forwarding_unit)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx;         // for id_ex_reg

wire reg_1_valid;                                           // for hazard_unit
wire reg_2_valid;                                           // for hazard_unit


//--------------------------------id_ex_reg------------------------------------//
wire ex_no_op;                                              // for alu (stop opeartions)
wire ex_reg_write_enable;                                   // for ex_mem_reg
wire [1:0] ex_mem_control;                                  // for ex_mem_reg
wire [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control;             // for alu
wire [`ISA_WIDTH - 1:0] ex_operand_1;                       // for alu (first oprand for alu)
wire [`ISA_WIDTH - 1:0] ex_operand_2;                       // for alu (second oprand for alu)
wire [`ISA_WIDTH - 1:0] ex_store_data;                      // for ex_mem_reg (the data to be store into memory)
wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_1_idx;             // for forwarding_unit
wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_2_idx;             // for forwarding_unit
wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx;          // for (1) forwarding_unit




wire ex_mem_read_enable;
assign ex_mem_read_enable = ex_mem_control[`MEM_READ_BIT];
//     (2) hazrad_unit
//     (3) ex_mem_reg



//--------------------------------stage-exe------------------------------------//

wire[`ISA_WIDTH - 1 : 0]          mem_result;
wire[`ISA_WIDTH - 1:0]            ex_alu_output;


//---------------------------------forwording----------------------------------//


wire [`REG_FILE_ADDR_WIDTH - 1 : 0] dest_mem, dest_wb;
wire                                mem_wb_en;
wire [`FORW_SEL_WIDTH - 1 : 0]      val1_sel, val2_sel;
wire [`FORW_SEL_WIDTH - 1 : 0]      st_sel;

//---------------------------------ex_mem_reg----------------------------------//


wire mem_no_op;                                   // for alu (stop opeartions)

wire mem_reg_write_enable;                        // for mem_wb_reg

wire [1:0] mem_mem_control;                       // for (1) data_mem: both read and write
//     (2) mem_wb_reg: only read
wire [`ISA_WIDTH - 1:0] mem_alu_result;           // for (1) data_mem (the read or write address)
//     (2) mem_wb_reg (the result of alu)
//     (3) alu (forwarding)

wire [`FORW_SEL_WIDTH - 1:0] store_data_select;   // from forwarding_unit (select which data to store)
wire [`ISA_WIDTH - 1:0] mem_alu_result_prev;      // from em_mem_reg (result of previous ex stage)
wire [`ISA_WIDTH - 1:0] mem_store_data;           // for data_mem (the data to be stored)

wire [`REG_FILE_ADDR_WIDTH - 1:0] mem_dest_reg;    // for (1) forwarding_unit
//     (2) harard_unit
//     (3) mem_wb_reg



//--------------------------------stage-mem------------------------------------//
wire [`ISA_WIDTH - 1:0] mem_read_data;         // for mem_wb_reg (the data read form memory)
wire input_enable;                             // for (1) input_unit (signal the keypad and switch to start reading)
//     (2) hazard_unit (trigger keypad hazard)
wire vga_write_enable;                         // for output_unit (write to vga display value register)
wire [`ISA_WIDTH - 1:0] vga_store_data;        // for output_unit (data to vga)


//---------------------------------mem-wb-reg--------------------------------//

wire wb_no_op;                                    // for general_reg (stop write opeartions)

wire wb_reg_write_enable;                         // for general_reg

wire mem_mem_read_enable;                         // from ex_mem_reg (whether data is read from memory)
assign mem_mem_read_enable = ex_mem_control[`MEM_READ_BIT];

wire wb_mem_read_enable;                          // for reg_write_select (to select data from memory)

wire [`ISA_WIDTH - 1:0] wb_alu_result;            // for (1) reg_write_select (result from alu)
//     (2) alu (forwarding)

wire [`ISA_WIDTH - 1:0] wb_mem_read_data;         // for reg_write_select (data from memory)

wire [`REG_FILE_ADDR_WIDTH - 1:0] wb_dest_reg;     // for (1) forwarding_unit


//--------------------------------stage-wb------------------------------------//

wire [`ISA_WIDTH - 1 : 0] wb_result;


//-------------------------------------uart_unit----------------------------------//


wire   uart_disable;                            // from hazard_unit (whether reading from uart)
wire   uart_clk;                                // from uart_unit (upg_clk_i)
wire   uart_write_enable;                       // from uart_unit (upg_wen_i)
wire   [`ISA_WIDTH - 1:0] uart_data;            // from uart_unit (upg_dat_i)
wire   [`DEFAULT_RAM_DEPTH:0] uart_addr;                 // from uart_unit (upg_adr_i)


//----------------------------------hazard-unit------------------------------------------//


wire pc_reset;                                        // for instruction_mem (reset the pc to 0)
wire [1:0] if_hazard_control,                         // hazard control signal for each stage register
     id_hazard_control,
     ex_hazard_control,
     mem_hazard_control,
     wb_hazard_control;
wire [2:0] issue_type;                                 // for vga_unit (both hazard and interrupt)


//-------------------------------------input_unit----------------------------------------//


wire [`SWITCH_CNT - 1:0] switch_map;          // from toggle switches directly

wire uart_complete;                           // from uart_unit (upg_done_i)

wire input_complete;                          // for hazard_unit (user pressed enter)
wire [`ISA_WIDTH - 1:0] input_data;           // for data_mem (data from user input)

wire switch_enable;                           // for (1) seven_seg_unit (user is using switches)
//     (2) output_unit (display that input is switches)
wire cpu_pause;                               // for hazard_unit (user pressed pause)

wire overflow;

//-------------------------------------output_unit----------------------------------------//

wire      [`COORDINATE_WIDTH - 1:0] x, y;



//-------------------------------------seven_seg_unit----------------------------------------//

wire  [`ISA_WIDTH - 1:0] display_value;    // from keypad_unit (value to be displayed)



//-------------------------------------keypad_unit_unit----------------------------------------//

wire [7:0] key_coord;


//--------------------------------------------vga_unit----------------------------------------//

wire clk_vga;                                       // need to change the frequency
wire  display_en;
wire hsync, vsync;


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
                    .hazard_control(if_hazard_control),

                    .if_no_op(if_no_op),
                    .pc(if_pc),                       //?
                    .instruction(if_instruction)
                );

//--------------------------------if-id-reg------------------------------------//
if_id_reg if_id_reg(
              .clk(clk),
              .rst_n(rst_n),
              .hazard_control(id_hazard_control),
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
                  .write_reg_addr(wb_dest_reg),
                  .write_data(wb_result),               // ? ? ?
                  .write_en(wb_reg_write_enable),       // ? ? ?
                  .wb_no_op(wb_no_op),
                  .id_no_op(id_no_op),
                  .read_data_1(read_data_1),
                  .read_data_2(read_data_2)
              );

condition_check condition_check(
                    .condition_type(branch_instruction),
                    .read_data_1(read_data_1),
                    .read_data_2(read_data_2),
                    .condition_satisfied(condition_satisfied)
                );


sign_extend sign_extend(
                .in(immediate),
                .out(extend_result)
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
            .wb_en(reg_write_en)
        );



signal_mux signal_mux(
               .i_type_instruction(i_type_instruction),
               .r_type_instruction(r_type_instruction),
               .j_instruction(j_instruction),
               .jr_instruction(jr_instruction),
               .jal_instruction(jal_instruction),
               .branch_instruction(branch_instruction),
               .store_instruction(store_instruction),

               .condition_satisfied(condition_satisfied),
               .pc_offset(pc_offset),

               .pc_overload(pc_overload),

               .id_reg_1(read_data_1),
               .id_pc(id_pc),
               .mux_operand_1(mux_operand_1),

               .id_reg_2 (read_data_2),
               .id_sign_extend_result(extend_result),
               .mux_operand_2(mux_operand_2),

               .id_instruction(id_instruction),
               .pc_overload_value(pc_overload_value),

               .id_reg_1_idx(read_reg_addr_1),
               .id_reg_2_idx(read_reg_addr_2),
               .id_reg_dest_idx(write_reg_addr),
               .mux_reg_1_idx(mux_reg_1_idx),
               .mux_reg_2_idx(mux_reg_2_idx),
               .mux_reg_dest_idx(mux_reg_dest_idx),

               .reg_1_valid(reg_1_valid),
               .reg_2_valid(reg_2_valid)
           );

//--------------------------------id_exe_reg------------------------------------//

id_ex_reg id_ex_reg(
              .clk(clk),
              .rst_n(rst_n),

              .hazard_control(ex_hazard_control),

              .id_no_op(id_no_op),
              .ex_no_op(ex_no_op),

              .id_reg_write_enable(reg_write_en),
              .ex_reg_write_enable(ex_reg_write_enable),

              .id_mem_control(mem_control),
              .ex_mem_control(ex_mem_control),

              .id_alu_control(alu_opcode),
              .ex_alu_control(ex_alu_control),

              .mux_operand_1(mux_operand_1),
              .ex_operand_1(ex_operand_1),

              .mux_operand_2(mux_operand_2),
              .ex_operand_2(ex_operand_2),

              .id_reg_2(read_data_2),
              .ex_store_data(ex_store_data),


              .mux_reg_1_idx(mux_reg_1_idx),
              .mux_reg_2_idx(mux_reg_2_idx),
              .mux_reg_dest_idx(mux_reg_dest_idx),
              .ex_reg_1_idx(ex_reg_1_idx),
              .ex_reg_2_idx(ex_reg_2_idx),
              .ex_reg_dest_idx(ex_reg_dest_idx)
          );


//----------------------------------hazard-unit------------------------------------------//

hazard_unit hazard_unit(
                .clk(clk),
                .rst_n(rst_n),

                .uart_complete(uart_complete),
                .uart_disable(uart_disable),
                .reg_1_valid(reg_1_valid),
                .reg_2_valid(reg_2_valid),
                .branch_instruction(branch_instruction),

                .ex_mem_read_enable(ex_mem_read_enable),
                .ex_reg_write_enable(ex_reg_write_enable),
                .ex_no_op(ex_no_op),
                .mem_reg_write_enable(mem_reg_write_enable),
                .mem_no_op(mem_no_op),

                .id_reg_1_idx(read_reg_addr_1),
                .id_reg_2_idx(read_reg_addr_2),
                .id_reg_dest_idx(write_reg_addr),
                .ex_reg_dest_idx(ex_reg_dest_idx),
                .mem_reg_dest_idx(mem_dest_reg),

                .pc_next(if_pc),

                .input_enable(input_enable),
                .input_complete(input_complete),
                .cpu_pause(cpu_pause),

                .pc_reset(pc_reset),
                .if_hazard_control(if_hazard_control),
                .id_hazard_control(id_hazard_control),
                .ex_hazard_control(ex_hazard_control),
                .mem_hazard_control(mem_hazard_control),
                .wb_hazard_control(wb_hazard_control),
                .issue_type(issue_type)

            );


//--------------------------------stage-exe------------------------------------//

alu alu(
        .alu_opcode(ex_alu_control),
        .alu_result(mem_alu_result),        //  ??
        .mem_result(mem_result),
        .val1_sel(val1_sel),
        .val2_sel(val2_sel),
        .a_input(mux_operand_1),
        .b_input(mux_operand_2),
        .alu_output(ex_alu_output)
    );

//----------------------------forwarding_unit----------------------------------//
forwarding_unit forwarding_unit(
                    .src1(ex_reg_1_idx),
                    .src2(ex_reg_2_idx),
                    .st_src(ex_reg_dest_idx),

                    .dest_mem(mem_dest_reg),            // ???
                    .dest_wb(wb_dest_reg),              // ???

                    .mem_wb_en(wb_reg_write_enable),
                    .wb_en(ex_reg_write_enable),

                    .val1_sel(val1_sel),
                    .val2_sel(val2_sel),
                    .st_sel(st_sel)
                );

//---------------------------------ex_mem_reg----------------------------------//

ex_mem_reg ex_mem_reg(
               .clk(clk),
               .rst_n(rst_n),

               .hazard_control(mem_hazard_control),

               .ex_no_op(ex_no_op),
               .mem_no_op(mem_no_op),

               .ex_reg_write_enable(ex_reg_write_enable),
               .mem_reg_write_enable(mem_reg_write_enable),

               .ex_mem_control(ex_mem_control),
               .mem_mem_control(mem_mem_control),

               .ex_alu_result(ex_alu_output),
               .mem_alu_result(mem_alu_result),

               .store_data_select(st_sel),             // ??
               .ex_store_data(ex_store_data),
               .mem_alu_result_prev(mem_alu_result),
               .wb_reg_write_data(wb_result),
               .mem_store_data(mem_store_data),

               .ex_dest_reg(ex_reg_dest_idx),
               .mem_dest_reg(mem_dest_reg)
           );


//--------------------------------stage-mem------------------------------------//
data_mem data_mem(
             .clk(clk),
             .rst_n(rst_n),

             .uart_disable(uart_disable),
             .uart_clk(uart_clk),
             .uart_write_enable(uart_write_enable),
             .uart_data(uart_data),
             .uart_addr(uart_addr),

             .no_op(ex_no_op),
             .mem_control(ex_mem_control),
             .mem_addr(mem_alu_result),
             .mem_store_data(mem_store_data),
             .mem_read_data(mem_read_data),

             .input_enable(input_enable),

             .input_data(input_data),

             .vga_write_enable(vga_write_enable),
             .vga_store_data(vga_store_data)

         );


//---------------------------------mem-wb-reg--------------------------------//

mem_wb_reg mem_wb_reg(
               .clk(clk),
               .rst_n(rst_n),
               .hazard_control(wb_hazard_control),
               .mem_no_op(mem_no_op),
               .wb_no_op(wb_no_op),
               .mem_reg_write_enable(mem_reg_write_enable),
               .wb_reg_write_enable(wb_reg_write_enable),
               .mem_mem_read_enable(mem_mem_read_enable),
               .wb_mem_read_enable(wb_mem_read_enable),
               .mem_alu_result(mem_alu_result),
               .wb_alu_result(wb_alu_result),
               .mem_mem_read_data(mem_read_data),
               .wb_mem_read_data(wb_mem_read_data),
               .mem_dest_reg(mem_dest_reg),
               .wb_dest_reg(wb_dest_reg)
           );



//--------------------------------stage-wb------------------------------------//
reg_with_select reg_with_select(
                    .wb_mem_read_data(wb_mem_read_data),
                    .wb_alu_result(wb_alu_result),
                    .wb_mem_read_enable(wb_mem_read_enable),
                    .wb_result(wb_result)
                );

//-------------------------------------uart_unit----------------------------------//







//-------------------------------------input_unit----------------------------------------//

input_unit input_unit(
               .clk(clk),
               .rst_n(rst_n),
               .key_coord(key_coord),
               .switch_map(switch_map),
               .uart_complete(uart_complete),
               .input_enable(input_enable),
               .input_complete(input_complete),
               .input_data(input_data),
               .switch_enable(switch_enable),
               .cpu_pause(cpu_pause),
               .overflow(overflow)
           );

//-------------------------------------output_unit----------------------------------------//

output_unit output_unit(
                .clk(clk),
                .rst_n(rst_n),
                .display_en(display_en),
                .x(x),
                .y(y),
                .vga_write_enable(vga_write_enable),
                .vga_store_data(vga_store_data),
                .issue_type(issue_type),
                .switch_enable(switch_enable),
                .vga_rgb(vga_rgb)
            );

//-------------------------------------seven_seg_unit----------------------------------------//

seven_seg_unit seven_seg_unit(
                   .clk(clk),
                   .rst_n(rst_n),
                   .display_value(display_value),
                   .switch_enable(switch_enable),
                   .input_enable(input_enable),
                   .seg_tube(seg_tube),
                   .seg_enable(seg_enable)
               );

//-------------------------------------keypad_unit_unit----------------------------------------//

keypad_unit keypad_unit(
                .clk(clk),
                .rst_n(rst_n),
                .row_in(row_in),
                .col_out(col_out),
                .key_coord(key_coord)
            );


//-------------------------------------vga_unit----------------------------------------------//


vga_unit vga_unit(
             .clk_vga(clk_vga),
             .rst_n(rst_n),
             .hsync(hsync),
             .vsync(vsync),
             .display_en(display_en),
             .x(x),
             .y(y)
         );



//-------------------------------------uart_unit----------------------------------------------//






endmodule
