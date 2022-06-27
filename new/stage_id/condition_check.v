`include "../definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        condition_type: beq or bnq
        read_data_1, read_data_2: data got from register files
        condition_satisfied:
*/
module condition_check (
    input [`COND_TYPE_WIDTH - 1:0]  condition_type,             // is branch type instruction
    input [`ISA_WIDTH - 1 : 0]      read_data_1, read_data_2,
    output reg                      condition_satisfied
);

wire eq = (read_data_1 == read_data_2) ? 1 : 0;

always @(*) begin
    case (condition_type)
        `CONDITION_TYPE_BEQ: condition_satisfied <= eq;
        `CONDITION_TYPE_BNQ: condition_satisfied <= ~eq;
        default:             condition_satisfied <= 0;
    endcase
end

endmodule