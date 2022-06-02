`include "../definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        alu_opcode: Determine what operations the ALU will execute. The data is generated by
                            control module
        a_input:    operand 1
        b_input:    operand 2
        alu_result: the alu result of last instruction, used to solve data hazard like below
                    add $s0, $t0, $t1
                    sub $t2, $s0, $t3
        reg_write_data: the data fetched from data memory, used to solve data hazard like below
                    lw $s0, 20($t1)
                    sub $t2, $s0, $t3
        val1_sel:   select signal of alu operand 1
        val2_sel:   select signal of alu operand 2
        sw_val_sel: select signal of value to be stored into memory

    Output:
        alu_output: Result calculated by ALU
*/
module alu (
    input [`ALU_CONTROL_WIDTH - 1:0]    alu_opcode,
    input [`ISA_WIDTH - 1 : 0]          alu_result, reg_write_data,
    input [`FORW_SEL_WIDTH - 1 : 0]     val1_sel, val2_sel,
    input [`ISA_WIDTH - 1 : 0]          a_input, b_input,
    output reg [`ISA_WIDTH - 1:0]       alu_output
);

reg [`ISA_WIDTH - 1 : 0] val1, val2, sw_val;

always @(*) begin
    case (val1_sel)
        `FORW_SEL_INPUT:    val1 = a_input;
        `FORW_SEL_ALU_RES:  val1 = alu_result;
        `FORW_SEL_MEM_RES:  val1 = reg_write_data;
        default:            val1 = 0;
    endcase 
    case (val2_sel)
        `FORW_SEL_INPUT:    val2 = b_input;
        `FORW_SEL_ALU_RES:  val2 = alu_result;
        `FORW_SEL_MEM_RES:  val2 = reg_write_data;
        default:            val2 = 0;
    endcase
end

always @(alu_opcode or val1 or val2) begin
    case (alu_opcode)
        `EXE_SLL:   alu_output = val2 << val1;                                    // sll
        `EXE_SRL:   alu_output = val2 >> val1;                                    // srl
        `EXE_SLLV:  alu_output = val2 << val1;                                    // sllv
        `EXE_SRLV:  alu_output = val2 >> val1;                                    // srlv
        `EXE_SRA:   alu_output = $signed(val2) >>> val1;                          // sra
        `EXE_SRAV:  alu_output = $signed(val2) >>> val1;                          // srav
        `EXE_ADD:   alu_output = $signed(val1) + $signed(val2);                   // add
        `EXE_ADDU:  alu_output = $unsigned(val1) + $unsigned(val2);               // addu
        `EXE_SUB:   alu_output = $signed(val1) - $signed(val2);                   // sub
        `EXE_SUBU:  alu_output = $unsigned(val1) - $unsigned(val2);               // subu
        `EXE_AND:   alu_output = val1 & val2;                                     // and
        `EXE_OR:    alu_output = val1 | val2;                                     // or
        `EXE_XOR:   alu_output = val1 ^ val2;                                     // xor
        `EXE_NOR:   alu_output = ~(val1 | val2);                                  // nor
        `EXE_SLT:   alu_output = ($signed(val1) < $signed(val2)) ? 1 : 0;         // slt
        `EXE_SLTU:  alu_output = ($unsigned(val1) < $unsigned(val2)) ? 1 : 0;     // sltu
        `EXE_ADDI:  alu_output = $signed(val1) + $signed(val2);                   // addi
        `EXE_ADDIU: alu_output = $unsigned(val1) + $unsigned(val2);               // addiu
        `EXE_SLTI:  alu_output = ($signed(val1) < $signed(val2)) ? 1 : 0;         // slti
        `EXE_SLTIU: alu_output = ($unsigned(val1) < $unsigned(val2)) ? 1 : 0;     // sltiu
        `EXE_ANDI:  alu_output = val1 & val2;                                     // andi
        `EXE_ORI:   alu_output = val1 | val2;                                     // ori
        `EXE_XORI:  alu_output = val1 ^ val2;                                     // xori
        `EXE_LUI:   alu_output = {val2[15:0], val1[15:0]};                        // lui
        default:    alu_output = 0;                                               // default
    endcase
end

endmodule