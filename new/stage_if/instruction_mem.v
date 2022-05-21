`include "../definitions.v"
`timescale 1ns / 1ps

/*
this module is implements the functionality of:
    (1) PC
    (2) ALU for PC
    (3) instruction memory
    (4) UART memory update

for UART:
    (1) all operations must be granted by the hazard_unit before allowing for any updates
    (2) the UART input data will be equally divided into two parts:
        [0x0000, 0x3FFF] data to update instruction memory
        [0x4000, 0x7FFF] data to update data memory
 */

module instruction_mem #(parameter 
    ROM_DEPTH = `DEFAULT_ROM_DEPTH
    )(
    input clk, rst_n,

    input uart_hazard,                          // from hazard_unit (UART hazard)
    input uart_clk,                             // from uart_unit (upg_clk_i)
    input uart_write_enable,                    // from uart_unit (upg_wen_i)
    input [`ISA_WIDTH - 1:0] uart_data,         // from uart_unit (upg_dat_i)
    input [ROM_DEPTH:0] uart_addr,              // from uart_unit (upg_adr_i)

    input pc_offset,                            // from id_ex_reg (from control_unit)
    input [`ISA_WIDTH - 1:0] pc_offset_value,   // from id_ex_reg (from sign_extend)

    input pc_overload,                          // from id_ex_reg (from control_unit)
    input [`ISA_WIDTH - 1:0] pc_overload_value, // from id_ex_reg (by the 31st register)

    input pc_hold,                              // from hazard_unit (discard pc reuslt and pause if)

    output reg [`ISA_WIDTH - 1:0] pc,           // for (1) if_id_reg (the current program counter)
                                                //     (2) hazard_unit (to detect UART hazard)
    output [`ISA_WIDTH - 1:0] instruction       // for if_id_reg (the current instruction)
    );

    wire uart_instruction_write_enable = uart_write_enable & ~uart_addr[ROM_DEPTH];
    reg [`ISA_WIDTH - 1:0] pc_next;
    reg no_op;

    ROM rom(
        .ena    (~no_op), // disabled unpon hold

        .clka   (uart_hazard ? uart_clk                   : clk),
        .addra  (uart_hazard ? uart_addr[ROM_DEPTH - 1:0] : pc[ROM_DEPTH - 1:0]), // pc address is in unit of words
        .douta  (instruction),

        .dina   (uart_hazard ? uart_data                     : 0),
        .wea    (uart_hazard ? uart_instruction_write_enable : 0)
    );
    
    always @(*) begin
        case ({pc_offset, pc_overload})
            2'b10:   pc_next <= pc + pc_offset_value;
            2'b01:   pc_next <= pc_overload_value + 1;
            default: pc_next <= pc + 1;
        endcase
    end
    
    always @(posedge clk) begin
        if (~rst_n) begin
            pc      <= 0;
            pc_next <= 0;
            no_op   <= 0;
        end else if (~pc_hold) begin
            pc      <= pc_next;
            no_op   <= 0;
        end else
            no_op   <= 1;
    end
    
endmodule