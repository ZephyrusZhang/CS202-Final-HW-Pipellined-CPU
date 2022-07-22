`timescale 1ns / 1ps
`include "../definitions.v"

module uart_unit (
    input  clk_uart,                            // upg_clk_i
    input  uart_disable,                        // upg_rst_i
    input  uart_rx,                             // upg_rx_i
    output uart_tx,                             // upg_tx_o
    output uart_clk_out,                        // upg_clk_o
    output [`RAM_DEPTH:0] uart_addr,    // upg_adr_o
    output [`ISA_WIDTH - 1:0] uart_data,        // upg_dat_o
    output uart_write_enable,                   // upg_wen_o
    output uart_complete                        // upg_done_o
);
    uart_interface uart_interface (
        .upg_clk_i(clk_uart),
        .upg_rst_i(uart_disable),
        .upg_rx_i(uart_rx),

        .upg_clk_o(uart_clk_out),
        .upg_wen_o(uart_write_enable),
        .upg_dat_o(uart_data),
        .upg_adr_o(uart_addr),
        .upg_done_o(uart_complete),
        .upg_tx_o(uart_tx)
    );
endmodule