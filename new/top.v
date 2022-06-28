`include "definitions.v"
`timescale 1ns / 1ps

module top (
    input      clk_raw, rst_n,
    input      [`SWITCH_CNT - 1:0] switch_map,              // 8 switches
    input      uart_rx,                                     // for uart_unit
    input      [3:0] row_in,
    output     [3:0] col_out,
    output     [7:0] seg_tube,   
    output     [7:0] seg_enable,
    output     [`VGA_BIT_DEPTH - 1:0] vga_signal,
    output     uart_in_progress,                            // LED indicator for UART process
    output     digit_overflow_9th,                          // LED indicator for seven seg tube digit overflow of 9th digit
    output     digit_overflow_10th,
    output     hsync, vsync,
    output     uart_tx                                      // from uart_unit
    );
    
    //// wire list, format: [signal_source]_[signal_name]
    
    // clocks
    wire clk_uart; // for uart_unit (10MHz)
    wire clk_vga;  // for vga_unit (25MHz)
    wire clk_cpu;  // for cpu components except hazard_unit (100MHz)
    
    clk_generator #(4)  vga_clk_generator (clk_raw, rst_n, clk_vga);
    clk_generator #(10) uart_clk_generator(clk_raw, rst_n, clk_uart);

    assign clk_cpu = clk_raw;
        
    // no_op
    wire instruction_mem_no_op,
         if_id_reg_no_op,
         id_ex_reg_no_op,
         ex_mem_reg_no_op,
         mem_wb_reg_no_op;

    // instruction
    wire [`ISA_WIDTH - 1:0] instruction_mem_instruction,
                            if_id_reg_instruction;
    // instruction segments
    wire [`OP_CODE_WIDTH - 1:0]   op_code   = if_id_reg_instruction[`ISA_WIDTH - 1:`ISA_WIDTH - `OP_CODE_WIDTH]; // op [31:26]
    wire [`FUNC_CODE_WIDTH - 1:0] func_code = if_id_reg_instruction[`FUNC_CODE_WIDTH - 1:0];
    wire [`IMMEDIATE_WIDTH - 1:0] immediate = if_id_reg_instruction[`IMMEDIATE_WIDTH - 1:0];
    wire [`SHIFT_AMOUNT_WIDTH - 1:0] 
        // shamt [25:21]
        shift_amount = if_id_reg_instruction[
            `ISA_WIDTH - `OP_CODE_WIDTH - (3 * `REG_FILE_ADDR_WIDTH) - 1
            :
            `ISA_WIDTH - `OP_CODE_WIDTH - (3 * `REG_FILE_ADDR_WIDTH) - `SHIFT_AMOUNT_WIDTH
        ];
    wire [`REG_FILE_ADDR_WIDTH - 1:0] 
        // rs [25:21]
        rs = if_id_reg_instruction[
            `ISA_WIDTH - `OP_CODE_WIDTH - 1
            :
            `ISA_WIDTH - `OP_CODE_WIDTH - `REG_FILE_ADDR_WIDTH
        ],
        // rt [20:16]
        rt = if_id_reg_instruction[
            `ISA_WIDTH - `OP_CODE_WIDTH - `REG_FILE_ADDR_WIDTH - 1
            :
            `ISA_WIDTH -`OP_CODE_WIDTH - (2 * `REG_FILE_ADDR_WIDTH)
        ],
        // rd [15:11]
        rd = if_id_reg_instruction[
            `ISA_WIDTH - `OP_CODE_WIDTH - (2 * `REG_FILE_ADDR_WIDTH) - 1
            :
            `ISA_WIDTH - `OP_CODE_WIDTH - (3 * `REG_FILE_ADDR_WIDTH)
        ];
    
    // pc
    wire [`ISA_WIDTH - 1:0] instruction_mem_pc,
                            if_id_reg_pc;

    // register_file data
    wire [`ISA_WIDTH - 1:0] reg_file_reg_1_data,
                            reg_file_reg_2_data,
                            id_ex_reg_store_data,
                            ex_mem_reg_store_data;
    
    // extended result
    wire [`ISA_WIDTH - 1:0] sign_extend_result;

    // signal multiplexor result
    wire [`ISA_WIDTH - 1:0] mux_operand_1,
                            mux_operand_2,       // this is pc_offset value as well
                            id_ex_reg_operand_1,
                            id_ex_reg_operand_2,
                            mux_pc_overload_value;
    wire [`REG_FILE_ADDR_WIDTH - 1:0] mux_reg_1_idx,
                                      mux_reg_2_idx,
                                      id_ex_reg_reg_1_idx,
                                      id_ex_reg_reg_2_idx,
                                      mux_reg_dest_idx,
                                      id_ex_reg_reg_dest_idx,
                                      ex_mem_reg_reg_dest_idx,
                                      mem_wb_reg_reg_dest_idx;
    wire mux_pc_offset,
         mux_pc_overload,
         mux_reg_1_valid,
         mux_reg_2_valid;

    // control signal
    wire [`ALU_CONTROL_WIDTH - 1:0] control_alu_op_code,
                                    id_ex_reg_alu_op_code;
    wire [`COND_TYPE_WIDTH - 1:0] control_condition_type;
    wire [1:0] control_mem_control,
               id_ex_reg_mem_control,
               ex_mem_reg_mem_control;
    wire mem_wb_reg_mem_read_enable;
    wire control_reg_write_enable,
         id_ex_reg_reg_write_enable,
         ex_mem_reg_reg_write_enable,
         mem_wb_reg_reg_write_enable;
    
    wire i_type_instruction,
         r_type_instruction,
         j_instruction,
         jr_instruction,
         jal_instruction,
         branch_instruction,
         store_instruction,
         shift_instruction;
    
    // condition check
    wire condition_check_satisfied;

    // alu
    wire [`ISA_WIDTH - 1:0] alu_alu_result,
                            ex_mem_reg_alu_result,
                            mem_wb_reg_alu_result;
    
    // forwarding unit
    wire [`FORW_SEL_WIDTH - 1:0] forwarding_oeprand_1_data_selection,
                                 forwarding_oeprand_2_data_selection,
                                 forwarding_store_data_selection;

    // data memory
    wire [`ISA_WIDTH - 1:0] data_mem_read_data,
                            mem_wb_reg_read_data,
                            data_mem_vga_store_data;
    wire data_mem_input_enable,
         data_mem_vga_write_enable;
    
    // reg wirte data selector
    wire [`ISA_WIDTH - 1:0] reg_write_select_reg_write_data;

    // hazard unit
    wire [`HAZD_CTL_WIDTH - 1:0] hazard_unit_if_hazard_control,
                                 hazard_unit_id_hazard_control,
                                 hazard_unit_ex_hazard_control,
                                 hazard_unit_mem_hazard_control,
                                 hazard_unit_wb_hazard_control;
    wire [`ISSUE_TYPE_WIDTH - 1:0] hazard_unit_issue_type;
    wire hazard_unit_pc_reset,
         hazard_unit_uart_disable,
         hazard_unit_ignore_no_op,
         hazard_unit_ignore_pause;

    // input unit
    wire [`ISA_WIDTH - 1:0] input_unit_keypad_data;
    wire input_unit_input_complete,
         input_unit_switch_enable,
         input_unit_cpu_pause;

    // vga sync 
    wire [`COORDINATE_WIDTH - 1:0] vga_unit_x, vga_unit_y;
    wire vga_unit_display_en;

    // keypad unit
    wire [7:0] keypad_unit_key_coord;

    // uart unit
    wire uart_unit_clk_out,
         uart_unit_write_enable,
         uart_unit_uart_complete;
    wire [`ISA_WIDTH - 1:0] uart_unit_write_data;
    wire [`DEFAULT_RAM_DEPTH:0] uart_unit_write_address;
            

    // LED
    assign uart_in_progress = hazard_unit_uart_disable ? 1'b0 : 1'b1;

    // always @(posedge clk_cpu, negedge rst_n) begin
    //     if (~rst_n)                         uart_in_progress <= 1'b0;
    //     else if (~hazard_unit_uart_disable) uart_in_progress <= 1'b1;
    //     else                                uart_in_progress <= 1'b0;
    // end

    //// module list

    //----------------------------forwarding_unit----------------------------------//
    forwarding_unit forwarding_unit(
        .src1                   (id_ex_reg_reg_1_idx),
        .src2                   (id_ex_reg_reg_2_idx),
        .st_src                 (id_ex_reg_reg_dest_idx),

        .dest_mem               (ex_mem_reg_reg_dest_idx),
        .dest_wb                (mem_wb_reg_reg_dest_idx),

        .dest_mem_no_op         (ex_mem_reg_no_op), 
        .dest_wb_no_op          (mem_wb_reg_no_op),

        .mem_wb_en              (ex_mem_reg_reg_write_enable),
        .wb_en                  (mem_wb_reg_reg_write_enable),

        .val1_sel               (forwarding_oeprand_1_data_selection),
        .val2_sel               (forwarding_oeprand_2_data_selection),
        .st_sel                 (forwarding_store_data_selection)
    );

    //-------------------------------hazard-unit------------------------------------//
    hazard_unit hazard_unit(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .uart_complete          (uart_unit_uart_complete),
        .uart_write_enable      (uart_unit_write_enable),
        .uart_disable           (hazard_unit_uart_disable),

        .reg_1_valid            (mux_reg_1_valid),
        .reg_2_valid            (mux_reg_2_valid),

        .branch_instruction     (branch_instruction),
        .store_instruction      (store_instruction),

        .if_no_op               (instruction_mem_no_op),

        .ex_mem_read_enable     (id_ex_reg_mem_control[`MEM_READ_BIT]),
        .ex_reg_write_enable    (id_ex_reg_reg_write_enable),
        .ex_no_op               (id_ex_reg_no_op),

        .mem_reg_write_enable   (ex_mem_reg_reg_write_enable),
        .mem_no_op              (ex_mem_reg_no_op),

        .id_reg_1_idx           (mux_reg_1_idx),
        .id_reg_2_idx           (mux_reg_2_idx),
        .id_reg_dest_idx        (mux_reg_dest_idx),
        .ex_reg_dest_idx        (id_ex_reg_reg_dest_idx),
        .mem_reg_dest_idx       (ex_mem_reg_reg_dest_idx),

        .pc                     (instruction_mem_pc),

        .input_enable           (data_mem_input_enable),
        .input_complete         (input_unit_input_complete),
        .cpu_pause              (input_unit_cpu_pause),
        .ignore_pause           (hazard_unit_ignore_pause),

        .pc_reset               (hazard_unit_pc_reset),

        .if_hazard_control      (hazard_unit_if_hazard_control),
        .id_hazard_control      (hazard_unit_id_hazard_control),
        .ex_hazard_control      (hazard_unit_ex_hazard_control),
        .mem_hazard_control     (hazard_unit_mem_hazard_control),
        .wb_hazard_control      (hazard_unit_wb_hazard_control),
        .ignore_no_op           (hazard_unit_ignore_no_op),

        .issue_type             (hazard_unit_issue_type)
    );

    //--------------------------------stage-if------------------------------------//
    instruction_mem instruction_mem(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .uart_disable           (hazard_unit_uart_disable),
        .uart_clk               (uart_unit_clk_out),
        .uart_write_enable      (uart_unit_write_enable),
        .uart_data              (uart_unit_write_data),
        .uart_addr              (uart_unit_write_address),

        .pc_offset              (mux_pc_offset),
        .pc_offset_value        (mux_operand_2),

        .pc_overload            (mux_pc_overload),
        .pc_overload_value      (mux_pc_overload_value),

        .pc_reset               (hazard_unit_pc_reset),
        .hazard_control         (hazard_unit_if_hazard_control),

        .if_no_op               (instruction_mem_no_op),

        .pc                     (instruction_mem_pc),                       
        .instruction            (instruction_mem_instruction)
    );

    //--------------------------------stage-id------------------------------------//
    if_id_reg if_id_reg(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .hazard_control         (hazard_unit_id_hazard_control),
        .ignore_no_op           (hazard_unit_ignore_no_op),

        .if_no_op               (instruction_mem_no_op),
        .id_no_op               (if_id_reg_no_op),

        .if_pc                  (instruction_mem_pc),
        .id_pc                  (if_id_reg_pc),

        .if_instruction         (instruction_mem_instruction),
        .id_instruction         (if_id_reg_instruction),

        .pc_offset              (mux_pc_offset),
        .pc_overload            (mux_pc_overload)
    );
    register_file register_file(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .read_reg_addr_1        (rs),
        .read_reg_addr_2        (rt),

        .write_reg_addr         (mem_wb_reg_reg_dest_idx),
        .write_data             (reg_write_select_reg_write_data),
        .write_en               (mem_wb_reg_reg_write_enable),
        .wb_no_op               (mem_wb_reg_no_op),

        .read_data_1            (reg_file_reg_1_data),
        .read_data_2            (reg_file_reg_2_data)
    );
    condition_check condition_check(
        .condition_type         (control_condition_type),
        .read_data_1            (reg_file_reg_1_data),
        .read_data_2            (reg_file_reg_2_data),
        .condition_satisfied    (condition_check_satisfied)
    );
    sign_extend sign_extend(
        .in                     (immediate),
        .out                    (sign_extend_result)
    );
    control control(
        .opcode                 (op_code),
        .func                   (func_code),

        .alu_opcode             (control_alu_op_code),
        .mem_control            (control_mem_control),

        .i_type_instruction     (i_type_instruction),
        .r_type_instruction     (r_type_instruction),
        .j_instruction          (j_instruction),
        .jr_instruction         (jr_instruction),
        .jal_instruction        (jal_instruction),
        .branch_instruction     (branch_instruction),
        .store_instruction      (store_instruction),
        .shift_instruction      (shift_instruction),

        .wb_en                  (control_reg_write_enable),
        .condition_type         (control_condition_type)
    );
    signal_mux signal_mux(
        .i_type_instruction     (i_type_instruction),
        .r_type_instruction     (r_type_instruction),
        .j_instruction          (j_instruction),
        .jr_instruction         (jr_instruction),
        .jal_instruction        (jal_instruction),
        .branch_instruction     (branch_instruction),
        .store_instruction      (store_instruction),
        .shift_instruction      (shift_instruction),

        .condition_satisfied    (condition_check_satisfied),
        .id_no_op               (if_id_reg_no_op),

        .pc_offset              (mux_pc_offset),
        .pc_overload            (mux_pc_overload),

        .id_reg_1               (reg_file_reg_1_data),
        .id_pc                  (if_id_reg_pc),
        .shift_amount           (shift_amount),
        .mux_operand_1          (mux_operand_1),

        .id_reg_2               (reg_file_reg_2_data),
        .id_sign_extend_result  (sign_extend_result),
        .mux_operand_2          (mux_operand_2),

        .id_instruction         (if_id_reg_instruction),
        .pc_overload_value      (mux_pc_overload_value),

        .id_reg_1_idx           (rs),
        .id_reg_2_idx           (rt),
        .id_reg_dest_idx        (rd),
        .mux_reg_1_idx          (mux_reg_1_idx),
        .mux_reg_2_idx          (mux_reg_2_idx),
        .mux_reg_dest_idx       (mux_reg_dest_idx),

        .reg_1_valid            (mux_reg_1_valid),
        .reg_2_valid            (mux_reg_2_valid)
    );

    //--------------------------------stage-if------------------------------------//
    id_ex_reg id_ex_reg(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .hazard_control         (hazard_unit_ex_hazard_control),
        .ignore_no_op           (hazard_unit_ignore_no_op),

        .id_no_op               (if_id_reg_no_op),
        .ex_no_op               (id_ex_reg_no_op),

        .id_reg_write_enable    (control_reg_write_enable),
        .ex_reg_write_enable    (id_ex_reg_reg_write_enable),

        .id_mem_control         (control_mem_control),
        .ex_mem_control         (id_ex_reg_mem_control),

        .id_alu_control         (control_alu_op_code),
        .ex_alu_control         (id_ex_reg_alu_op_code),

        .mux_operand_1          (mux_operand_1),
        .ex_operand_1           (id_ex_reg_operand_1),

        .mux_operand_2          (mux_operand_2),
        .ex_operand_2           (id_ex_reg_operand_2),

        .id_reg_2               (reg_file_reg_2_data),
        .ex_store_data          (id_ex_reg_store_data),

        .mux_reg_1_idx          (mux_reg_1_idx),
        .mux_reg_2_idx          (mux_reg_2_idx),
        .mux_reg_dest_idx       (mux_reg_dest_idx),
        .ex_reg_1_idx           (id_ex_reg_reg_1_idx),
        .ex_reg_2_idx           (id_ex_reg_reg_2_idx),
        .ex_reg_dest_idx        (id_ex_reg_reg_dest_idx)
    );

    //---------------------------------stage-ex----------------------------------//
    alu alu(
        .alu_opcode             (id_ex_reg_alu_op_code),
        .alu_result             (ex_mem_reg_alu_result),
        .reg_write_data         (reg_write_select_reg_write_data),
        .val1_sel               (forwarding_oeprand_1_data_selection),
        .val2_sel               (forwarding_oeprand_2_data_selection),
        .a_input                (id_ex_reg_operand_1),
        .b_input                (id_ex_reg_operand_2),
        .alu_output             (alu_alu_result)
    );
    ex_mem_reg ex_mem_reg(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .hazard_control         (hazard_unit_mem_hazard_control),
        .ignore_no_op           (hazard_unit_ignore_no_op),

        .ex_no_op               (id_ex_reg_no_op),
        .mem_no_op              (ex_mem_reg_no_op),

        .ex_reg_write_enable    (id_ex_reg_reg_write_enable),
        .mem_reg_write_enable   (ex_mem_reg_reg_write_enable),

        .ex_mem_control         (id_ex_reg_mem_control),
        .mem_mem_control        (ex_mem_reg_mem_control),

        .ex_alu_result          (alu_alu_result),
        .mem_alu_result         (ex_mem_reg_alu_result),

        // select signal
        .store_data_select      (forwarding_store_data_selection),
        // to be selected
        .ex_store_data          (id_ex_reg_store_data),
        .mem_alu_result_prev    (ex_mem_reg_alu_result),
        .wb_reg_write_data      (reg_write_select_reg_write_data),
        // select output
        .mem_store_data         (ex_mem_reg_store_data),

        .ex_dest_reg_idx        (id_ex_reg_reg_dest_idx),
        .mem_dest_reg_idx       (ex_mem_reg_reg_dest_idx)
    );

    //--------------------------------stage-mem------------------------------------//
    data_mem data_mem(
        .clk                    (clk_cpu),

        .uart_disable           (hazard_unit_uart_disable),
        .uart_clk               (uart_unit_clk_out),
        .uart_write_enable      (uart_unit_write_enable),
        .uart_data              (uart_unit_write_data),
        .uart_addr              (uart_unit_write_address),

        .no_op                  (ex_mem_reg_no_op),
        .mem_control            (ex_mem_reg_mem_control),
        .mem_addr               (ex_mem_reg_alu_result),
        .mem_store_data         (ex_mem_reg_store_data),
        .mem_read_data          (data_mem_read_data),

        .input_enable           (data_mem_input_enable),

        .vga_write_enable       (data_mem_vga_write_enable)
    );
    mem_wb_reg mem_wb_reg(
        .clk                    (clk_cpu),
        .rst_n                  (rst_n),

        .hazard_control         (hazard_unit_wb_hazard_control),
        .ignore_no_op           (hazard_unit_ignore_no_op),

        .mem_no_op              (ex_mem_reg_no_op),
        .wb_no_op               (mem_wb_reg_no_op),

        .mem_reg_write_enable   (ex_mem_reg_reg_write_enable),
        .wb_reg_write_enable    (mem_wb_reg_reg_write_enable),

        .mem_mem_read_enable    (ex_mem_reg_mem_control[`MEM_READ_BIT]),
        .wb_mem_read_enable     (mem_wb_reg_mem_read_enable),

        .mem_alu_result         (ex_mem_reg_alu_result),
        .wb_alu_result          (mem_wb_reg_alu_result),

        .input_enable           (data_mem_input_enable),
        .switch_enable          (input_unit_switch_enable),
        .mem_mem_read_data      (data_mem_read_data),
        .keypad_data            (input_unit_keypad_data),
        .switch_map             (switch_map),
        .wb_mem_read_data       (mem_wb_reg_read_data),

        .mem_dest_reg_idx       (ex_mem_reg_reg_dest_idx),
        .wb_dest_reg_idx        (mem_wb_reg_reg_dest_idx)
    );

    //--------------------------------stage-wb------------------------------------//
    reg_with_select reg_with_select(
        // select signal
        .wb_mem_read_enable     (mem_wb_reg_mem_read_enable),
        // to be selected
        .wb_alu_result          (mem_wb_reg_alu_result),
        .wb_mem_read_data       (mem_wb_reg_read_data),
        // select output
        .wb_result              (reg_write_select_reg_write_data)
    );

    //-----------------------------------input---------------------------------------//
    uart_unit uart_unit(
        .clk_uart               (clk_uart),
        .uart_disable           (hazard_unit_uart_disable),
        .uart_rx                (uart_rx),
        
        .uart_tx                (uart_tx),
        .uart_clk_out           (uart_unit_clk_out),
        .uart_addr              (uart_unit_write_address),
        .uart_data              (uart_unit_write_data),
        .uart_write_enable      (uart_unit_write_enable),
        .uart_complete          (uart_unit_uart_complete)
    );
    keypad_unit keypad_unit(
        .clk                    (clk_raw),
        .rst_n                  (rst_n),
        .row_in                 (row_in),
        .col_out                (col_out),
        .key_coord              (keypad_unit_key_coord)
    );
    input_unit input_unit(
        .clk                    (clk_raw),
        .rst_n                  (rst_n),
        .key_coord              (keypad_unit_key_coord),
        .ignore_pause           (hazard_unit_ignore_pause),
        .input_enable           (data_mem_input_enable),
        .input_complete         (input_unit_input_complete),
        .keypad_data            (input_unit_keypad_data),
        .switch_enable          (input_unit_switch_enable),
        .cpu_pause              (input_unit_cpu_pause),
        .overflow_9th           (digit_overflow_9th),
        .overflow_10th          (digit_overflow_10th)
    );

    //-------------------------------------output----------------------------------------//
    seven_seg_unit seven_seg_unit(
        .clk                    (clk_raw),
        .rst_n                  (rst_n),
        .keypad_data            (input_unit_keypad_data),
        .switch_map             (switch_map),
        .switch_enable          (input_unit_switch_enable),
        .input_enable           (data_mem_input_enable),
        .seg_tube               (seg_tube),
        .seg_enable             (seg_enable)
    );
    vga_unit vga_unit(
        .clk_vga                (clk_vga),
        .rst_n                  (rst_n),
        .hsync                  (hsync),
        .vsync                  (vsync),
        .display_en             (vga_unit_display_en),
        .x                      (vga_unit_x),
        .y                      (vga_unit_y)
    );
    output_unit output_unit(
        .clk                    (clk_raw),
        .rst_n                  (rst_n),
        .display_en             (vga_unit_display_en),
        .x                      (vga_unit_x),
        .y                      (vga_unit_y),
        .vga_write_enable       (data_mem_vga_write_enable),
        .vga_store_data         (ex_mem_reg_store_data),
        .issue_type             (hazard_unit_issue_type),
        .switch_enable          (input_unit_switch_enable),
        .vga_rgb                (vga_signal)
    );
endmodule