`define DEFAULT_RAM_DEPTH   14              // ram size
`define DEFAULT_ROM_DEPTH   14              // rom size
`define ISA_WIDTH           32
`define IO_START_BIT        10
`define IO_END_BIT          31
`define IO_HIGH_ADDR        22'h3FFFFF
`define IO_TYPE_BIT         4
`define ALU_CONTROL_WIDTH   6               // width of alu exe code
`define OP_CODE_WIDTH       6
`define REGISTER_SIZE       5
`define FUNC_CODE_WIDTH     6

`define MEM_WRITE_BIT       0
`define MEM_READ_BIT        1

`define HAZD_HOLD_BIT       0
`define HAZD_NO_OP_BIT      1

`define ADDRES_WIDTH        26

//------------------------------Register File-----------------------------------//
`define REG_FILE_ADDR_WIDTH 5               // width of register address(idx)
//------------------------------------------------------------------------------//

//----------------------------------ALU-----------------------------------------//
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