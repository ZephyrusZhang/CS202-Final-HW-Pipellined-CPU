`include "../definitions.v"
`timescale 1ns / 1ps

/*
    Input:
        condition_type: beq or bnq
        read_data_1, read_data_2: data got from register files
        condition_result:
*/
module condition_check (
    input                       condition_type,
    input [`ISA_WIDTH - 1 : 0]  read_data_1, read_data_2,
    output reg                  condition_result
);

wire eq = (read_data_1 == read_data_2) ? 1 : 0;

always @(*) begin
    case (condition_type)
        `CONDITION_TYPE_BEQ: condition_result <= eq;
        `CONDITION_TYPE_BNQ: condition_result <= ~eq;
        default:             condition_result <= 0;
    endcase
end

endmodule