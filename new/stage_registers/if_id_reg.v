`include "../definitions.v"
`timescale 1ns / 1ps

/*
this is the stage register between:
    instruction fetch (if) stage
    instruction decoding (id) stage
 */

module if_id_reg (
    input clk, rst_n,

    input      [`HAZD_CTL_WIDTH - 1:0] hazard_control,  // from hazard_unit (specifies the next state for id stage)
    input      ignore_no_op,                            // from hazard_unit (whether to ignore no_op from if stage)

    input      if_no_op,                                // from instruction_mem (the operations of if have been stoped)
    output reg id_no_op,                                // for general_reg (stop opeartions)

    input      [`ISA_WIDTH - 1:0] if_pc,                // from instruction_mem (pc + 4)
    output reg [`ISA_WIDTH - 1:0] id_pc,                // for id_ex_reg (to store into 31st register)

    input      [`ISA_WIDTH - 1:0] if_instruction,       // from instruction_mem (the current instruction)
    output reg [`ISA_WIDTH - 1:0] id_instruction,       // for control_unit (the current instruction)

    input      pc_offset,                               // from signal_mux
    input      pc_overload                              // from signal_mux
    );

    wire pc_abnormal = pc_offset | pc_overload; // prediction (default pc + 4) failed

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            {
                id_no_op,

                id_pc,
                id_instruction
            }                  <= 0;
        end else if (pc_abnormal | (if_no_op & ~ignore_no_op))
                id_no_op       <= 1'b1;
        else case (hazard_control)
            `HAZD_CTL_NO_OP: 
                id_no_op       <= 1'b1;
            `HAZD_CTL_RETRY: 
                id_no_op       <= 1'b0;
            /* this is the `HAZD_CTL_NORMAL state */
            default        : begin
                id_no_op       <= 1'b0;
                
                id_pc          <= if_pc;
                id_instruction <= if_instruction;
            end
        endcase
    end
    
endmodule