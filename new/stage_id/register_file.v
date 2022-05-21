`include "../definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        clk:        clock signal
        rs, rt, rd:
        write_data: the data to be written into register, which comes from alu result or memory
        i_type:     indicate whether the current instruction is I type. 0 => not, 1 => yes
        write_en:   indicate whether be able to write data into register
        sw:         whether instruction sw
        jal:        whether instruction jal
    Output:
        read_data_1: comes from rs
        read_data_2: comes from rt
*/
module register_file (
    input clk, rst_n,
    input [`REG_FILE_ADDR_WIDTH - 1 : 0] rs, rt, rd,
    input [`ISA_WIDTH - 1 : 0] write_data,
    input i_type,
    input write_en,
    input sw,
    input jal,
    output [`ISA_WIDTH - 1 : 0] read_data_1, read_data_2
);

reg [`REG_FILE_ADDR_WIDTH - 1 : 0] read_reg_addr_1, read_reg_addr_2, write_reg_addr;
always @(*) begin
    read_reg_addr_1 = rs;
    read_reg_addr_2 = rt;
    if (i_type)     write_reg_addr = rt;
    else if (jal)   write_reg_addr = 31;
    else if (sw)    write_reg_addr = 0;
    else            write_reg_addr = rd;
end

reg [`ISA_WIDTH - 1 : 0] registers [0 : `ISA_WIDTH - 1];
integer i;

assign read_data_1 = registers[rs];
assign read_data_2 = registers[rt];

always @(posedge clk) begin
    if (~rst_n) begin
        for (i = 0; i < `ISA_WIDTH; i = i + 1)
            registers[i] <= 0;
    end else
        if (write_en)
            registers[write_reg_addr] <= write_data;
end

endmodule