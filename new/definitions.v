//----------------------------ISA Specifications--------------------------------//
`define ISA_WIDTH           32              // width of a word in the ISA
`define ADDRES_WIDTH        26              // address lenth in instruction for j and jal extension
//------------------------------------------------------------------------------//

//---------------------------------Memory---------------------------------------//
`define DEFAULT_RAM_DEPTH   14              // ram size = 2^DEFAULT_RAM_DEPTH
`define DEFAULT_ROM_DEPTH   14              // rom size = 2^DEFAULT_ROM_DEPTH
//------------------------------------------------------------------------------//

//-----------------------------------IO-----------------------------------------//
`define IO_START_BIT        10              // lowest bit of memory_mapped IO address
`define IO_END_BIT          31              // highest bit of memory-mapped IO address
`define IO_HIGH_ADDR        22'h3FFFFF      // address used identify memory-mapped IO
`define IO_TYPE_BIT         4               // bit for determining IO type 
//------------------------------------------------------------------------------//

//---------------------------------Control--------------------------------------//
`define OP_CODE_WIDTH       6               // width of oepration code
`define FUNC_CODE_WIDTH     6               // width of function code

`define MEM_WRITE_BIT       0               // bit for determining memory write enable
`define MEM_READ_BIT        1               // bit for determining memory read enable
//------------------------------------------------------------------------------//

//---------------------------------Hazard---------------------------------------//
`define HAZD_HOLD_BIT       0               // bit for determining hazard hold signal
`define HAZD_NO_OP_BIT      1               // bit for determining hazard no operation signal
//------------------------------------------------------------------------------//

//------------------------------Register File-----------------------------------//
`define REG_FILE_ADDR_WIDTH 5               // width of register address(idx)
//------------------------------------------------------------------------------//

//----------------------------------ALU-----------------------------------------//
`define ALU_CONTROL_WIDTH   6               // width of alu exe code

// ALU opcode: used to determine what operations the ALU will execute
`define EXE_SLL             6'b00_0000
`define EXE_SRL             6'b00_0010
`define EXE_SLLV            6'b00_0100
`define EXE_SRLV            6'b00_0110
`define EXE_SRA             6'b00_0011
`define EXE_SRAV            6'b00_0111
`define EXE_ADD             6'b10_0000
`define EXE_ADDU            6'b10_0001
`define EXE_SUB             6'b10_0010
`define EXE_SUBU            6'b10_0011
`define EXE_AND             6'b10_0100
`define EXE_OR              6'b10_0101
`define EXE_XOR             6'b10_0110
`define EXE_NOR             6'b10_0111
`define EXE_SLT             6'b10_1010
`define EXE_SLTU            6'b10_1011
`define EXE_ADDI            6'b00_1000
`define EXE_ADDIU           6'b00_1001
`define EXE_SLTI            6'b00_1010
`define EXE_SLTIU           6'b00_1011
`define EXE_ANDI            6'b00_1100
`define EXE_ORI             6'b00_1101
`define EXE_XORI            6'b00_1110
`define EXE_LUI             6'b00_1111
//------------------------------------------------------------------------------//

//--------------------------------Forwarding------------------------------------//
`define FORW_SEL_WIDTH      2                   //width of forwarding select signal
`define FORW_SEL_INPUT      2'b00               //indicate to select register input
`define FORW_SEL_ALU_RES    2'b01               //indicate to select ALU result
`define FORW_SEL_MEM_RES    2'b10               //indicate to select data fetched from memory 
//------------------------------------------------------------------------------//

//----------------------------Condition Check-----------------------------------//
`define CONDITION_TYPE_BEQ 0
`define CONDITION_TYPE_BNQ 1
//------------------------------------------------------------------------------//