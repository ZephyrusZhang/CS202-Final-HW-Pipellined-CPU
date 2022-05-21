`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2022/05/14 21:57:31
// Design Name:
// Module Name: executs32
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,Shamt,ALUSrc,I_format,Zero,Jr,Sftmd,ALU_Result,Addr_Result,PC_plus_4);

// 来自于Decoder
input[31:0]             Read_data_1;		// 从译码单元的Read_data_1中来
input[31:0]             Read_data_2;		// 从译码单元的Read_data_2中来
input[31:0]             Sign_extend;		// 从译码单元来的扩展后的立即数

// 来自于IFetch
input[5:0]              Exe_opcode;  		// 取址单元来的操作码
input[5:0]              Function_opcode;  	// 取址单元来的r-类型指令功能码,r-form instructions[5:0]
input[4:0]              Shamt;              // 来自取指单元的instruction[10:6]，指定移位次数
input[31:0]             PC_plus_4;          // 来自取指单元的PC+4

// 来自于Controller
input[1:0]              ALUOp;              // 来自控制单元的运算指令控制编码
input                   ALUSrc;             // 来自控制单元，表明第二个操作数是立即数(beq，bne除外)还是寄存器
input                   I_format;           // 来自控制单元，表明是除beq, bne, LW, SW之外的I-类型指令
input                   Jr;                 // 来自控制单元，表明是JR指令
input  		            Sftmd;              // 来自控制单元的，表明是移位指令

output                  Zero;               // 为1表明计算值为0(用于beq和bnq的有条件跳转的条件的计算)
output[31:0]            ALU_Result;         // 计算的数据结果
output[31:0]            Addr_Result;        // 计算的地址结果

wire[31:0]  Ainput, Binput;                 // 两个操作数
wire[5:0]   Exe_code;                       // 用于产生ALU_ctl
wire[2:0]   ALU_ctl;                        // 影响操作的控制信号
wire[2:0]   Sftm;                           // 辨别移位指令的类型(数值上等于Function_opcode[2:0])
reg[31:0]   Shift_Result;                   // 移位操作的结果
reg[31:0]   ALU_output_mux;                 // 算数或逻辑运算的结果
reg[31:0]   ALU_Result_Reg;
wire[32:0]  Branch_Addr;                    // 指令的计算地址, Addr_Result是Banch_Addr [31:0]

assign Ainput = Read_data_1;
assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0];
assign Exe_code = (I_format == 0) ? Function_opcode : {3'b000, Exe_opcode[2:0]};
assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];
assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
assign Sftm = Function_opcode[2:0];

always @(*) begin // six types of shift instructions
    if(Sftmd)
        case(Sftm[2:0])
            3'b000:     Shift_Result = Binput << Shamt;             //Sll   rd,rt,shamt 00000
            3'b010:     Shift_Result = Binput >> Shamt;             //Srl   rd,rt,shamt 00010
            3'b100:     Shift_Result = Binput << Ainput;            //Sllv  rd,rt,rs 00010
            3'b110:     Shift_Result = Binput >> Ainput;            //Srlv  rd,rt,rs 00110
            3'b011:     Shift_Result = $signed(Binput) >> Shamt;    //Sra   rd,rt,shamt 00011
            3'b111:     Shift_Result = $signed(Binput) >> Ainput;   //Srav  rd,rt,rs 00111
            default:    Shift_Result = Binput;
        endcase
    else
        Shift_Result = Binput;
end

always @(ALU_ctl or Ainput or Binput) begin
    case(ALU_ctl)
        3'b000:     ALU_output_mux = Ainput & Binput;
        3'b001:     ALU_output_mux = Ainput | Binput;
        3'b010:     ALU_output_mux = $signed(Ainput) + $signed(Binput);
        3'b011:     ALU_output_mux = $unsigned(Ainput) + $unsigned(Binput);
        3'b100:     ALU_output_mux = Ainput ^ Binput;
        3'b101:     ALU_output_mux = ~(Ainput | Binput);
        3'b110:     ALU_output_mux = $signed(Ainput) - $signed(Binput);
        3'b111:     ALU_output_mux = $unsigned(Ainput) - $unsigned(Binput);
        default:    ALU_output_mux = 32'h00000000;
    endcase
end

always @(*) begin
    if (((ALU_ctl == 3'b110) && (Exe_code == 4'b0010)) || ((ALU_ctl == 3'b111) && (Exe_code[0] == 1'b1)))
        ALU_Result_Reg = (ALU_output_mux < 0) ? 1'b1 : 1'b0;
    else if ((ALU_ctl == 3'b111) && (Exe_code[0] == 1'b0))
        ALU_Result_Reg = (($signed(Ainput) - $signed(Binput)) < 0) ? 1'b1 : 1'b0;
    else if ((ALU_ctl == 3'b101) && (I_format == 1))
        ALU_Result_Reg = {Binput[15:0], 16'h0000};
    else if (Sftmd == 1)
        ALU_Result_Reg = Shift_Result;
    else
        ALU_Result_Reg = ALU_output_mux[31:0];
end

assign Zero = (ALU_Result_Reg == 32'h0000_0000) ? 1'b1 : 1'b0;
assign Branch_Addr = $signed(PC_plus_4) + $signed((Sign_extend << 2));
assign Addr_Result = Branch_Addr[31:0];
assign ALU_Result = ALU_Result_Reg;

endmodule
