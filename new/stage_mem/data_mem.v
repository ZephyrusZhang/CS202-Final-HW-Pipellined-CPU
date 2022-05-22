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
    input clk, rst_n,


    input      uart_hazard,                             // from hazard_unit (UART hazard)
    input      uart_clk,                                // from uart_unit (upg_clk_i)
    input      uart_write_enable,                       // from uart_unit (upg_wen_i)
    input      [`ISA_WIDTH - 1:0] uart_data,            // from uart_unit (upg_dat_i)
    input      [ROM_DEPTH:0] uart_addr,                 // from uart_unit (upg_adr_i)

    input      [`ISA_WIDTH - 1:0] mem_address,          // from ex_mem_reg (by alu_result)

    input      mem_write_enable,                        // from ex_mem_reg (by control_unit)
    input      [`ISA_WIDTH - 1:0] mem_store_data,       // from ex_mem_reg (by general_reg)
    
    input      mem_read_enable,                         // from ex_mem_reg (by control_unit)
    input      [`ISA_WIDTH - 1:0] keypad_read_data,     // data from keypad to output from mem_read_data
    output     [`ISA_WIDTH - 1:0] mem_read_data,        // for mem_wb_reg (the data read form memory)

    input      no_op,                                   // from ex_mem_reg (stop read and write)
    
    output     keypad_read_enable,                      // signal the keypad to start reading

    output     vga_write_enable,                        // vga write enable
    output     [`ISA_WIDTH - 1:0] vga_store_data        // data to vga
    );

    wire io_active = (mem_address[`IO_START_BIT:`IO_END_BIT] == `IO_HIGH_ADDR);
    wire uart_instruction_write_enable = uart_write_enable & uart_addr[ROM_DEPTH];

    assign keypad_read_enable = ~mem_address[`IO_TYPE_BIT] & io_active & mem_read_enable;
    assign vga_write_enable   =  mem_address[`IO_TYPE_BIT] & io_active & mem_write_enable;

    RAM ram(
        .ena    (~no_op), // disabled unpon no_op

        .clka   (uart_hazard ? uart_clk                   : clk),
        .addra  (uart_hazard ? uart_addr[ROM_DEPTH + 1:2] : mem_address[ROM_DEPTH + 1:2]), // address unit in bytes
        .douta  (mem_read_data),

        .dina   (uart_hazard      ? uart_data                     : (
                 vga_write_enable ? 0                             : mem_store_data)),
        .wea    (uart_hazard      ? uart_instruction_write_enable : (
                 vga_write_enable ? 0                             : mem_write_enable))
    );

    assign vga_store_data = mem_store_data;
    
endmodule