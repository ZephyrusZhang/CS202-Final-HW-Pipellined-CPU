`include "../definitions.v"
`timescale 1ns / 1ps

/*
this module is to implement the functionality of:
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

    input      uart_disable,                            // from hazard_unit (whether reading from uart)
    input      uart_clk,                                // from uart_unit (upg_clk_i)
    input      uart_write_enable,                       // from uart_unit (upg_wen_i)
    input      [`ISA_WIDTH - 1:0] uart_data,            // from uart_unit (upg_dat_i)
    input      [ROM_DEPTH:0] uart_addr,                 // from uart_unit (upg_adr_i)
    
    input      pc_offset,                               // from signal_mux
    input      [`ISA_WIDTH - 1:0] pc_offset_value,      // from signal_mux (mux_operand_2)
    
    input      pc_overload,                             // from signal_mux
    input      [`ISA_WIDTH - 1:0] pc_overload_value,    // from signal_mux (pc_overload_value)
    
    input      pc_reset,                                // from hazard_unit (reset pc when UART is completed)
    input      [`HAZD_CTL_WIDTH - 1:0] hazard_control,  // from hazard_unit (specifies the next state for if stage)

    output reg if_no_op,                                // for if_id_reg (stop id operations)

    output reg [`ISA_WIDTH - 1:0] pc,                   // for (1) hazard_unit (to detect UART hazard)
                                                        //     (2) if_id_reg (jal store into 31st register)
    output     [`ISA_WIDTH - 1:0] instruction           // for if_id_reg (the current instruction)
    );

    wire uart_instruction_write_enable = uart_write_enable & ~uart_addr[ROM_DEPTH];
    reg [`ISA_WIDTH - 1:0] pc_next;

    ROM rom(
        .ena    (~if_no_op), // disabled unpon no_op

        .clka   (uart_disable ? ~clk                : uart_clk),
        .addra  (uart_disable ? pc[ROM_DEPTH + 1:2] : uart_addr[ROM_DEPTH - 1:0]), // pc address is in unit of bytes
        .douta  (instruction),

        .dina   (uart_disable ? 1'b0 : uart_data),
        .wea    (uart_disable ? 1'b0 : uart_instruction_write_enable)
    );
    
    always @(*) begin
        case ({pc_offset, pc_overload, pc_reset})
            3'b100 : pc_next = pc + (pc_offset_value << 2);
            3'b010 : pc_next = pc_overload_value;
            3'b001 : pc_next = 0;
            default: pc_next = pc + 4;
        endcase
    end
    
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                if_no_op,
                pc
            }                <= 0;
        end else begin
            case (hazard_control)
                `HAZD_CTL_NO_OP: begin
                    if_no_op <= 1'b1;
                    
                    if (pc_offset | pc_overload) pc <= pc_next;
                    else                         pc <= pc;      // prevent auto latches
                end
                `HAZD_CTL_RETRY: 
                    if_no_op <= 1'b0;
                /* this is the `HAZD_CTL_NORMAL state */
                default        : begin
                    if_no_op <= 1'b0;
                    pc       <= pc_next;
                end
            endcase
        end
    end
    
endmodule