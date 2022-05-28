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


wire  [`ISA_WIDTH - 1 : 0]              reg_write_data;                              //from register_file
wire                                    reg_write_en;                                //from register_file
wire                                    wb_no_op;                                    //to register_file
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
wire  pc_offset;                                            // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_offset_value;                   // from signal_mux (mux_operand_2)
wire  pc_overload;                                          // from signal_mux
wire  [`ISA_WIDTH - 1:0] pc_overload_value;                 // from signal_mux (pc_overload_value)



wire [`ISA_WIDTH - 1:0] mux_operand_1;                // for id_ex_reg (to pass on to alu)
wire [`ISA_WIDTH - 1:0] mux_operand_2;                // for (1) id_ex_reg (to pass on to alu)

wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx;      // for id_ex_reg (to pass on to forwarding_unit)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_2_idx;      // for id_ex_reg (to pass on to forwarding_unit)
wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_dest_idx;   // for id_ex_reg

wire reg_1_valid;                                     // for hazard_unit
wire reg_2_valid;                                     // for hazard_unit


//--------------------------------id_exe_reg------------------------------------//
wire ex_no_op;                                         // for alu (stop opeartions)
wire ex_reg_write_enable;                              // for ex_mem_reg
wire [1:0] ex_mem_control;                             // for ex_mem_reg
wire [`ALU_CONTROL_WIDTH - 1:0] ex_alu_control;        // for alu
wire [`ISA_WIDTH - 1:0] ex_operand_1;                  // for alu (first oprand for alu)
wire [`ISA_WIDTH - 1:0] ex_operand_2;                  // for alu (second oprand for alu)
wire [`ISA_WIDTH - 1:0] ex_store_data;                 // for ex_mem_reg (the data to be store into memory)
wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_1_idx;        // for forwarding_unit
wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_2_idx;        // for forwarding_unit
wire [`REG_FILE_ADDR_WIDTH - 1:0] ex_reg_dest_idx;     // for (1) forwarding_unit
                                                       //     (2) hazrad_unit
                                                       //     (3) ex_mem_reg



//--------------------------------stage-exe------------------------------------//

  wire[`ISA_WIDTH - 1 : 0]          alu_result, mem_result;
  wire[`ISA_WIDTH - 1:0]            alu_output;



//---------------------------------forwording----------------------------------//


wire [`REG_FILE_ADDR_WIDTH - 1 : 0] dest_mem, dest_wb;
wire                                mem_wb_en; 
wire [`FORW_SEL_WIDTH - 1 : 0]      val1_sel, val2_sel;
wire [`FORW_SEL_WIDTH - 1 : 0]      st_sel;

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
                  .reg_write_data(write_data),
                  .reg_write_en(write_en),
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


sign_extend sign_extend(
                .immediate(in),
                .extend_result(out)
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
            .reg_write_en(wb_en)
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

               .read_data_1(id_reg_1),
               .id_pc(id_pc),
               .mux_operand_1(mux_operand_1),

               .read_data_2(id_reg_2),
               .extend_result(id_sign_extend_result),
               .mux_operand_2(mux_operand_2),

               .id_instruction(id_instruction),
               .pc_overload_value(pc_overload_value),

               .read_reg_addr_1(id_reg_1_idx),
               .read_reg_addr_2(id_reg_2_idx),
               .write_reg_addr(id_reg_dest_idx),
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
    
        .hazard_control(hazard_control),

        .id_no_op(id_no_op),
        .ex_no_op(ex_no_op),

        .reg_write_en(id_reg_write_enable),
        .ex_reg_write_enable(ex_reg_write_enable),

        .mem_control(id_mem_control),
        .ex_mem_control(ex_mem_control),

        .alu_opcode(id_alu_control),
        .ex_alu_control(ex_alu_control),

        .mux_operand_1(mux_operand_1),
        .ex_operand_1(ex_operand_1),

        .mux_operand_2(mux_operand_2),
        .ex_operand_2(ex_operand_2),

        .read_data_2(id_reg_2),
        .ex_store_data(ex_store_data),
    

        .mux_reg_1_idx(mux_reg_1_idx),
        .mux_reg_2_idx(mux_reg_2_idx),
        .mux_reg_dest_idx(mux_reg_dest_idx),
        .ex_reg_1_idx(ex_reg_1_idx),
        .ex_reg_2_idx(ex_reg_2_idx),
        .ex_reg_dest_idx(ex_reg_dest_idx)
);

//--------------------------------stage-exe------------------------------------//

alu alu(
    .ex_alu_control(alu_opcode),
    .alu_result(alu_result),
    .mem_result(mem_result),
    .val1_sel(val1_sel),
    .val2_sel(val2_sel),
    .mux_operand_1(a_input),
    .mux_operand_2(b_input),
    .alu_output(alu_output)
);

//----------------------------forwarding_unit----------------------------------//
forwarding_unit forwarding_unit(
    .ex_reg_1_idx(src1),
    .ex_reg_2_idx(src2),    
    .ex_reg_dest_idx(st_src),
    .dest_mem(dest_mem),
    .dest_wb(dest_wb),

    .mem_wb_en(mem_wb_en),
    .ex_reg_write_enable(wb_en),

    .val1_sel(val1_sel),
    .val2_sel(val2_sel),
    .st_sel(st_sel)

)



endmodule
