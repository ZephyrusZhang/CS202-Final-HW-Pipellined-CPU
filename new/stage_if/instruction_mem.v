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

    input      uart_hazard,                             // from hazard_unit (UART hazard)
    input      uart_clk,                                // from uart_unit (upg_clk_i)
    input      uart_write_enable,                       // from uart_unit (upg_wen_i)
    input      [`ISA_WIDTH - 1:0] uart_data,            // from uart_unit (upg_dat_i)
    input      [ROM_DEPTH:0] uart_addr,                 // from uart_unit (upg_adr_i)
    
    input      pc_offset,                               // from id_ex_reg (from control_unit)
    input      [`ISA_WIDTH - 1:0] pc_offset_value,      // from id_ex_reg (from operand_2)
    
    input      pc_overload,                             // from id_ex_reg (from control_unit)
    input      [`ISA_WIDTH - 1:0] pc_overload_value,    // from id_ex_reg (from operand_1)
    
    input      [1:0] hazard_control,                    // from hazard_unit [HAZD_HOLD_BIT] discard pc_next result
                                                        //                  [HAZD_if_no_op_BIT] pause if stage
    output reg if_no_op,                                // for if_id_reg (stop id operations)

    output reg [`ISA_WIDTH - 1:0] pc,                   // for (1) hazard_unit (to detect UART hazard)
                                                        //     (2) if_id_reg (jal store into 31st register)
    output     [`ISA_WIDTH - 1:0] instruction           // for if_id_reg (the current instruction)
    );

    wire uart_instruction_write_enable = uart_write_enable & ~uart_addr[ROM_DEPTH];
    reg [`ISA_WIDTH - 1:0] pc_next;

    ROM rom(
        .ena    (~if_no_op), // disabled unpon hold

        .clka   (uart_hazard ? uart_clk                   : clk),
        .addra  (uart_hazard ? uart_addr[ROM_DEPTH + 1:2] : pc[ROM_DEPTH + 1:2]), // pc address is in unit of bytes
        .douta  (instruction),

        .dina   (uart_hazard ? uart_data                     : 0),
        .wea    (uart_hazard ? uart_instruction_write_enable : 0)
    );
    
    always @(*) begin
        case ({pc_offset, pc_overload})
            2'b10:   pc_next <= pc + 4 + (pc_offset_value << 2);
            2'b01:   pc_next <= pc_overload_value;
            default: pc_next <= pc + 4;
        endcase
    end
    
    always @(posedge clk) begin
        if (~rst_n) begin
            pc       <= 0;
            if_no_op <= 0;
        end else if (hazard_control[`HAZD_HOLD_BIT]) pc <= pc;
        else                                         pc <= pc_next;

        if_no_op <= hazard_control[`HAZD_NO_OP_BIT];
    end
    
endmodule