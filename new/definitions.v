//----------------------------ISA Specifications--------------------------------//
`define ISA_WIDTH           32              // width of a word in the ISA
`define ADDRES_WIDTH        26              // address lenth of instructions for j and jal extension
`define STAGE_CNT           5
`define SHIFT_AMOUNT_WIDTH  5
`define JAL_REG_IDX         31
`define IMMEDIATE_WIDTH     16
//------------------------------------------------------------------------------//

//---------------------------------Memory---------------------------------------//
`define DEFAULT_RAM_DEPTH   14              // ram size = 2^DEFAULT_RAM_DEPTH
`define DEFAULT_ROM_DEPTH   14              // rom size = 2^DEFAULT_ROM_DEPTH
`define PC_MAX_VALUE        65_535          // ((1 << (`DEFAULT_ROM_DEPTH + 2)) - 1)

`define MEM_WRITE_BIT       0               // bit for determining memory write enable
`define MEM_READ_BIT        1               // bit for determining memory read enable
//------------------------------------------------------------------------------//

//-----------------------------------IO-----------------------------------------//
`define IO_START_BIT        8               // lowest bit of memory_mapped IO address
`define IO_END_BIT          31              // highest bit of memory-mapped IO address
`define IO_HIGH_ADDR        24'hFFFFFC      // address used identify memory-mapped IO
`define IO_TYPE_BIT         4               // bit for determining IO type 
`define SWITCH_CNT          8

// VGA display parameters
`define DISPLAY_WIDTH       640
`define DISPLAY_HEIGHT      480
`define COORDINATE_WIDTH    10
`define LEFT_BORDER         48
`define RIGHT_BORDER        16
`define TOP_BORDER          33
`define BOTTOM_BORDER       10
`define H_RETRACE           96              // horizontal retrace period
`define V_RETRACE           2               // vertical retrace period

// VGA colors
`define BG_COLOR            12'b110111011101    // light gray
`define DIGITS_BOX_BG_COLOR 12'b110011001100    // dark gray

// VGA display asset parameters
`define VGA_BIT_DEPTH       12

`define DIGITS_BOX_WIDTH    492
`define DIGITS_BOX_HEIGHT   40
`define DIGITS_BOX_X        74
`define DIGITS_BOX_Y        215

`define DIGITS_WIDTH        468
`define DIGITS_W_WIDTH      9               // width 468 <= 2^9
`define DIGITS_HEIGHT       16
`define DIGITS_X            86
`define DIGITS_Y            227
`define DIGITS_IDX_WIDTH    6               // number of digits 39 + 7 <= 2^6

`define DIGIT_WIDTH         12
`define DIGIT_W_WIDTH       4               // width 12 <= 2^4
`define DIGIT_H_WIDTH       4               // height 16 <= 2^4

`define STATUS_WIDTH        88
`define STATUS_W_WIDTH      7               // width 88 <= 2^7
`define STATUS_HEIGHT       22
`define STATUS_H_WIDTH      5               // height 22 <= 2^5
`define STATUS_X            291
`define STATUS_Y            180
//------------------------------------------------------------------------------//

//---------------------------------Control--------------------------------------//
`define OP_CODE_WIDTH       6               // width of oepration code
`define FUNC_CODE_WIDTH     6               // width of function code

`define OP_SLL              6'b00_0000
`define OP_SRL              6'b00_0010
`define OP_SLLV             6'b00_0100
`define OP_SRLV             6'b00_0110
`define OP_SRA              6'b00_0011
`define OP_SRAV             6'b00_0111
//------------------------------------------------------------------------------//

//---------------------------------Hazard---------------------------------------//
// index for the specific stage registers (both hold and no_op)
`define HAZD_IF_IDX         0
`define HAZD_ID_IDX         1
`define HAZD_EX_IDX         2
`define HAZD_MEM_IDX        3
`define HAZD_WB_IDX         4

// signals for the stage registers (hazard_control)
`define HAZD_CTL_WIDTH      2
`define HAZD_CTL_NORMAL     2'b00           // normal execution state
`define HAZD_CTL_RETRY      2'b01           // deny values from pervious stage only
`define HAZD_CTL_NO_OP      2'b11           // deny values from previous stage and no_op the next stage
// `define HAZD_CTL_RESUME     2'b10           // no hold and do not accept no_op signal from previous stage

// values of issue_type 
`define ISSUE_TYPE_WIDTH    3
`define ISSUE_NONE          3'b000
`define ISSUE_DATA          3'b001
`define ISSUE_CONTROL       3'b010          // not handled by hazard_unit (determined after negedge with pc_abnormal in if_id_reg)
`define ISSUE_UART          3'b011          // during uart transmission only
`define ISSUE_PAUSE         3'b100
`define ISSUE_VGA           3'b101          // not handled by hazard_unit (as this typically holds only for a few cycles)
`define ISSUE_KEYPAD        3'b110
`define ISSUE_FALLTHROUGH   3'b111          // the next instruction address exceeds `PC_MAX_VALUE 
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
`define EXE_NO_OP           6'b11_1111
//------------------------------------------------------------------------------//

//--------------------------------Forwarding------------------------------------//
`define FORW_SEL_WIDTH      2                   //width of forwarding select signal
`define FORW_SEL_INPUT      2'b00               //indicate to select register input
`define FORW_SEL_ALU_RES    2'b01               //indicate to select ALU result
`define FORW_SEL_MEM_RES    2'b10               //indicate to select data fetched from memory 
//------------------------------------------------------------------------------//

//----------------------------Condition Check-----------------------------------//
`define COND_TYPE_WIDTH     2                   // width of condition type
`define COND_TYPE_BEQ       2'b10
`define COND_TYPE_BNQ       2'b11
`define NOT_BRANCH          2'b00
//------------------------------------------------------------------------------//