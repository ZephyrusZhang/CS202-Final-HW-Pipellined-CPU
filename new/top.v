`include "definitions.v"
`timescale 1ns / 1ps

module top (
    input  clk, rst_n,
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
    
    //// wire list

    // clocks
    wire uart_clk_out;                                      // from uart_unit (upg_clk_o)
    wire uart_clk_in;                                       // for uart_unit (10MHz)
    wire clk_vga;                                           // for vga_unit (25MHz)

    //--------------------------------stage-if------------------------------------//
    wire [`ISA_WIDTH - 1:0] if_pc;                          // from instruction_mem (pc + 4)
    wire if_no_op;                                          // for if_id_reg (stop id operations)
    wire [`ISA_WIDTH - 1:0] if_instruction;                 // from instruction_mem (the current instruction)

    //--------------------------------if_id_reg-----------------------------------//
    wire [`ISA_WIDTH - 1:0] id_pc;                          // for id_ex_reg (to store into 31st register)
    wire id_no_op;                                          // for general_reg (stop opeartions)
    wire [`ISA_WIDTH - 1:0] id_instruction;                 // for control_unit (the current instruction)

    //--------------------------------stage-id------------------------------------//
    wire [`REG_FILE_ADDR_WIDTH - 1:0] rs, rt, rd;           // decoding from pc
    wire [`OP_CODE_WIDTH - 1:0] opcode;
    wire [`ISA_WIDTH - 1:0] extend_result;

    // op [31:26]
    assign opcode = id_pc[`ISA_WIDTH-1:`ISA_WIDTH -`OP_CODE_WIDTH];
    // rs [25:21]
    assign rs = id_pc[`ISA_WIDTH - `OP_CODE_WIDTH - 1:`ISA_WIDTH - `OP_CODE_WIDTH - `REG_FILE_ADDR_WIDTH];
    // rt [20:16]
    assign rt = id_pc[`ISA_WIDTH - `OP_CODE_WIDTH - `REG_FILE_ADDR_WIDTH - 1:`ISA_WIDTH -`OP_CODE_WIDTH- 2 * `REG_FILE_ADDR_WIDTH];
    // rd [15:11]
    assign rd = id_pc[`ISA_WIDTH - `OP_CODE_WIDTH - (2 * `REG_FILE_ADDR_WIDTH) - 1:`ISA_WIDTH - `OP_CODE_WIDTH - (3 * `REG_FILE_ADDR_WIDTH)];

    wire id_reg_write_enable;                           // for future register_file
    
    wire [`ISA_WIDTH - 1:0] read_data_1, read_data_2;   // from register_file
    wire [`ALU_CONTROL_WIDTH - 1:0] id_alu_opcode;      // for alu
    wire [1:0] id_mem_control;                          // for data_mem

    wire i_type_instruction;                            // from control_unit (whether it is a I type instruction)
    wire r_type_instruction;                            // from control_unit (whether it is a R type instruction)
    wire j_instruction;                                 // from control_unit (whether it is a jump instruction)
    wire jr_instruction;                                // from control_unit (whether it is a jr instruction)
    wire jal_instruction;                               // from control_unit (whether it is a jal insutrction)
    wire branch_instruction;                            // from control_unit (whether it is a branch instruction)
    wire store_instruction;                             // from control_unit (whether it is a strore instruction)
    wire [1:0] condition_type;                          // for condition_check
    wire condition_satisfied;                           // from condition_check
    wire pc_offset;                                     // from signal_mux (whether to offset the pc)
    wire [`ISA_WIDTH - 1:0] pc_offset_value;            // from signal_mux (mux_operand_2)
    wire pc_overload;                                   // from signal_mux (whether to overload the pc)
    wire [`ISA_WIDTH - 1:0] pc_overload_value;          // from signal_mux (pc_overload_value)

    wire [`ISA_WIDTH - 1:0] mux_operand_1;              // for id_ex_reg (to pass on to alu)
    wire [`ISA_WIDTH - 1:0] mux_operand_2;              // for (1) id_ex_reg (to pass on to alu)
                                                        //     (2) instruction_mem

    wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx;    // for id_ex_reg (to pass on to forwarding_unit)
    wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx;    // for id_ex_reg (to pass on to forwarding_unit)
    wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx; // for id_ex_reg

    wire reg_1_valid;                                   // for hazard_unit
    wire reg_2_valid;                                   // for hazard_unit

    //--------------------------------id_exe_reg------------------------------------//
    wire ex_no_op;                                      // for alu (stop opeartions)
    wire ex_reg_write_enable;                           // for ex_mem_reg
    wire [1:0] ex_mem_control;                          // for ex_mem_reg
    wire [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control;     // for alu
    wire [`ISA_WIDTH - 1:0] ex_operand_1;               // for alu (first oprand for alu)
    wire [`ISA_WIDTH - 1:0] ex_operand_2;               // for alu (second oprand for alu)
    wire [`ISA_WIDTH - 1:0] ex_store_data;              // for ex_mem_reg (the data to be store into memory)
    wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_1_idx;     // for forwarding_unit
    wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_2_idx;     // for forwarding_unit
    wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx;  // for (1) forwarding_unit
                                                        //     (2) hazrad_unit
                                                        //     (3) ex_mem_reg

    //--------------------------------stage-exe------------------------------------//
    wire[`ISA_WIDTH - 1:0] ex_alu_output;               // from alu

    //---------------------------------forwording----------------------------------//
    wire [`REG_FILE_ADDR_WIDTH - 1:0] dest_mem, dest_wb;
    wire mem_wb_enable, wb_wb_enable;                   // write back enable from mem and wb stage
    wire [`FORW_SEL_WIDTH - 1:0] val1_sel, val2_sel;    // for alu (operand selection)
    wire [`FORW_SEL_WIDTH - 1:0] store_data_select;     // for ex_mem_reg (store data selection)

    //---------------------------------ex_mem_reg----------------------------------//
    wire mem_no_op;                                     // for alu (stop opeartions)
    wire mem_reg_write_enable;                          // for mem_wb_reg
    wire [1:0] mem_mem_control;                         // for (1) data_mem: both read and write
                                                        //     (2) mem_wb_reg: only read
    wire [`ISA_WIDTH - 1:0] mem_alu_result;             // for (1) data_mem (the read or write address)
                                                        //     (2) mem_wb_reg (the result of alu)
                                                        //     (3) alu (forwarding)
    wire [`ISA_WIDTH - 1:0] mem_store_data;             // for data_mem (the data to be stored)
    wire [`REG_FILE_ADDR_WIDTH - 1:0] mem_dest_reg_idx; // for (1) forwarding_unit
                                                        //     (2) harard_unit
                                                        //     (3) mem_wb_reg

    //--------------------------------stage-mem------------------------------------//
    wire [`ISA_WIDTH - 1:0] mem_read_data;              // for mem_wb_reg (the data read form memory)
    wire input_enable;                                  // for (1) input_unit (signal the keypad and switch to start reading)
                                                        //     (2) hazard_unit (trigger keypad hazard)
                                                        //     (3) seven_seg_unit (display input value)
    wire vga_write_enable;                              // for output_unit (write to vga display value register)
    wire [`ISA_WIDTH - 1:0] vga_store_data;             // for output_unit (data to vga)

    //---------------------------------mem-wb-reg--------------------------------//
    wire wb_no_op;                                      // to register_file
    wire wb_mem_read_enable;                            // for reg_write_select (to select data from memory)
    wire [`ISA_WIDTH - 1:0] wb_alu_result;              // for (1) reg_write_select (result from alu)
                                                        //     (2) alu (forwarding)
    wire [`ISA_WIDTH - 1:0] mem_mem_read_data;          // from data_mem (data read)
    wire [`ISA_WIDTH - 1:0] wb_mem_read_data;           // for reg_write_select (data from memory)
    wire [`REG_FILE_ADDR_WIDTH - 1:0] wb_dest_reg_idx;  // for (1) forwarding_unit

    //--------------------------------stage-wb------------------------------------//
    wire [`ISA_WIDTH - 1:0] wb_reg_write_data;          // from reg_write_select in wb stage
    wire wb_reg_write_enable;                           // for register_file

    //-------------------------------------uart_unit----------------------------------//
    wire uart_disable;                                  // from hazard_unit (whether reading from uart)
    wire uart_complete;                                 // from uart_unit (upg_done_i)
    wire uart_write_enable;                             // from uart_unit (upg_wen_i)
    wire [`ISA_WIDTH - 1:0] uart_data;                  // from uart_unit (upg_dat_i)
    wire [`DEFAULT_RAM_DEPTH:0] uart_addr;              // from uart_unit (upg_adr_i)

    //----------------------------------hazard-unit------------------------------------------//
    wire pc_reset;                                      // for instruction_mem (reset the pc to 0)
    wire [1:0] if_hazard_control,                       // hazard control signal for each stage register
               id_hazard_control,
               ex_hazard_control,
               mem_hazard_control,
               wb_hazard_control;
    wire [2:0] issue_type;                              // for vga_unit (both hazard and interrupt)

    //-------------------------------------input_unit----------------------------------------//
    wire [`SWITCH_CNT - 1:0] switch_map;                // from toggle switches directly
    wire input_complete;                                // for hazard_unit (user pressed enter)
    wire [`ISA_WIDTH - 1:0] input_data;                 // for data_mem (data from user input)
    wire switch_enable;                                 // for (1) seven_seg_unit (user is using switches)
                                                        //     (2) output_unit (display that input is switches)
    wire cpu_pause;                                     // for hazard_unit (user pressed pause)

    //-------------------------------------output_unit----------------------------------------//
    wire [`COORDINATE_WIDTH - 1:0] x, y;                // from vga_unit

    //-------------------------------------seven_seg_unit----------------------------------------//
    wire  [`ISA_WIDTH - 1:0] display_value;             // from keypad_unit (value to be displayed)

    //-------------------------------------keypad_unit_unit----------------------------------------//
    wire [7:0] key_coord;                               // for input_unit 

    //--------------------------------------------vga_unit----------------------------------------//
    wire display_en;                                    // for input_unit

    //// module list

    //--------------------------------stage-if------------------------------------//
    instruction_mem instruction_mem(
        .clk(clk),                                      // cpu_clk 100MHz
        .rst_n(rst_n),

        .uart_disable(uart_disable),
        .uart_clk(uart_clk_out),
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
        .pc(if_pc),                       
        .instruction(if_instruction)
    );

    //--------------------------------if-id-reg------------------------------------//
    if_id_reg if_id_reg(
        .clk(clk),
        .rst_n(rst_n),

        .hazard_control(id_hazard_control),
        .pc_offset(pc_offset),
        .pc_overload(pc_overload)

        .id_no_op(id_no_op),
        .id_pc(id_pc),
        .if_instruction(if_instruction),

        .if_no_op(if_no_op),
        .if_pc(if_pc),
        .id_instruction(id_instruction),
    );
    
    //--------------------------------stage-id------------------------------------//
    register_file register_file(
        .clk(clk),
        .rst_n(rst_n),

        .read_reg_addr_1(rs),
        .read_reg_addr_2(rt),
        .write_reg_addr(wb_dest_reg_idx),
        .write_data(wb_reg_write_data),
        .write_en(wb_reg_write_enable),
        .wb_no_op(wb_no_op),

        .id_no_op(id_no_op),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2)
    );

    condition_check condition_check(
        .condition_type(condition_type),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .condition_satisfied(condition_satisfied)
    );

    sign_extend sign_extend(
        .in(id_pc[`IMMEDIATE_WIDTH - 1:0]),         // address I type: low 16-bit
        .out(extend_result)
    );

    control control(
        .opcode(opcode),
        .func(id_pc[`FUNC_CODE_WIDTH - 1:0]),       // function code

        .alu_opcode(id_alu_opcode),
        .mem_control(id_mem_control),

        .i_type_instruction(i_type_instruction),
        .r_type_instruction(r_type_instruction),
        .j_instruction(j_instruction),
        .jr_instruction(jr_instruction),
        .jal_instruction(jal_instruction),
        .branch_instruction(branch_instruction),
        .store_instruction(store_instruction),

        .wb_en(id_reg_write_enable),
        .condition_type(condition_type)
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

        .id_reg_1_idx(rs),
        .id_reg_2_idx(rt),
        .id_reg_dest_idx(rd),
        .mux_reg_1_idx(mux_reg_1_idx),
        .mux_reg_2_idx(mux_reg_2_idx),
        .mux_reg_dest_idx(mux_reg_dest_idx),

        .reg_1_valid(reg_1_valid),
        .reg_2_valid(reg_2_valid)
    );

    //--------------------------------id_ex_reg------------------------------------//
    id_ex_reg id_ex_reg(
        .clk(clk),
        .rst_n(rst_n),

        .hazard_control(ex_hazard_control),

        .id_no_op(id_no_op),
        .ex_no_op(ex_no_op),

        .id_reg_write_enable(id_reg_write_enable),
        .ex_reg_write_enable(ex_reg_write_enable),

        .id_mem_control(id_mem_control),
        .ex_mem_control(ex_mem_control),

        .id_alu_control(id_alu_opcode),
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

        .id_reg_1_idx(mux_reg_1_idx),
        .id_reg_2_idx(mux_reg_2_idx),
        .ex_reg_dest_idx(ex_reg_dest_idx),
        .mem_reg_dest_idx(mem_dest_reg_idx),

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
        .alu_result(mem_alu_result),
        .wb_reg_write_data(wb_reg_write_data),
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

        .dest_mem(mem_dest_reg_idx),                // ???
        .dest_wb(wb_dest_reg_idx),                  // ???

        .mem_wb_en(wb_reg_write_enable),
        .wb_en(ex_reg_write_enable),

        .val1_sel(val1_sel),
        .val2_sel(val2_sel),
        .store_data_select(store_data_select)
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
               .wb_reg_write_data(wb_reg_write_data),
               .mem_store_data(mem_store_data),

.ex_dest_reg(ex_reg_dest_idx),
.mem_dest_reg_idx(mem_dest_reg_idx)
);


//--------------------------------stage-mem------------------------------------//
data_mem data_mem(
.clk(clk),
.rst_n(rst_n),

.uart_disable(uart_disable),
.uart_clk(uart_clk_out),
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
               .mem_dest_reg_idx(mem_dest_reg_idx),
               .wb_dest_reg_idx(wb_dest_reg_idx)
           );



//--------------------------------stage-wb------------------------------------//
reg_with_select reg_with_select(
                    .wb_mem_read_data(wb_mem_read_data),
                    .wb_alu_result(wb_alu_result),
                    .wb_mem_read_enable(wb_mem_read_enable),
                    .wb_result(wb_reg_write_data)
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
