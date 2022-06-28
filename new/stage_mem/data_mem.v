`include "../definitions.v"
`timescale 1ns / 1ps

/*
this module determines whether the address (from ex_mem_reg) is for IO or for memory
the total addressable space of 32bits is 2^2^30 = 4GB
 
address utilized:
    data memory (RAM):  4bytes * 16K = 64KB [0x00000000, 0x00010000]
    IO:                 placed into         [0xFFFFFC00, 0xFFFFFFFF]
        not implemented:
        -------------------------------------------------------------------------------------
        LED     1  - 16 [0xFFFFFC60, 0xFFFFFC61] when data to output is larger  than 8bits
        LED     17 - 24 [0xFFFFFC62, 0xFFFFFC62] when data to input  is smaller than 8bits
        switch  1  - 16 [0xFFFFFC70, 0xFFFFFC71] when data to output is larger  than 8bits
        switch  17 - 24 [0xFFFFFC72, 0xFFFFFC72] when data to input  is smaller than 8bits

        implemented:
        -------------------------------------------------------------------------------------
        keypad  1  - 32 [0xFFFFFC60, 0xFFFFFC63] capable of inputing   32bits in binary
        VGA     1  - 32 [0xFFFFFC70, 0xFFFFFC73] capable of displaying 32bits in binary
 */

module data_mem #(parameter 
    ROM_DEPTH = `DEFAULT_ROM_DEPTH                      // size of addressable memory
    )(
    input clk,

    input      uart_disable,                            // from hazard_unit (whether reading from uart)
    input      uart_clk,                                // from uart_unit (upg_clk_i)
    input      uart_write_enable,                       // from uart_unit (upg_wen_i)
    input      [`ISA_WIDTH - 1:0] uart_data,            // from uart_unit (upg_dat_i)
    input      [ROM_DEPTH:0] uart_addr,                 // from uart_unit (upg_adr_i)

    input      no_op,                                   // from ex_mem_reg (stop read and write)
    input      [1:0] mem_control,                       // from ex_mem_reg (by control_unit)
    input      [`ISA_WIDTH - 1:0] mem_addr,             // from ex_mem_reg (by alu_result)
    input      [`ISA_WIDTH - 1:0] mem_store_data,       // from ex_mem_reg (by general_reg)    
    output     [`ISA_WIDTH - 1:0] mem_read_data,        // for mem_wb_reg (the data read from memory)

    output     input_enable,                            // for (1) input_unit (signal the keypad and switch to start reading)
                                                        //     (2) hazard_unit (trigger keypad hazard)
                                                        //     (3) seven_seg_unit (display input value)
                                                        //     (4) mem_wb_reg (select the appropriate data to write back)

    output     vga_write_enable                         // for output_unit (write to vga display value register)
    );

    wire io_active = (mem_addr[`IO_END_BIT:`IO_START_BIT] == `IO_HIGH_ADDR);
    wire uart_instruction_write_enable = uart_write_enable & uart_addr[ROM_DEPTH];

    assign input_enable     = (~mem_addr[`IO_TYPE_BIT] & io_active & mem_control[`MEM_READ_BIT])  ? 1'b1 : 1'b0;
    assign vga_write_enable = (mem_addr [`IO_TYPE_BIT] & io_active & mem_control[`MEM_WRITE_BIT]) ? 1'b1 : 1'b0;

    RAM ram(
        .ena    (~no_op), // disabled unpon no_op

        .clka   ((uart_disable == 1'b1) ? ~clk                      : uart_clk),
        .addra  ((uart_disable == 1'b1) ? mem_addr[ROM_DEPTH + 1:2] : uart_addr[ROM_DEPTH - 1:0]),  // address unit in bytes
        .douta  (mem_read_data),

        .dina   ((uart_disable == 1'b1) ? (vga_write_enable ? 1'b0 : mem_store_data) : uart_data),
        .wea    ((uart_disable == 1'b1) ? (vga_write_enable ? 1'b0 : mem_control[`MEM_WRITE_BIT]) : uart_instruction_write_enable)
    );

endmodule