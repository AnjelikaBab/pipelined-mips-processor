LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY controlLogicUnit IS
    PORT(
        opcode : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- 6-bit opcode
        regDst : OUT STD_LOGIC;
        jump : OUT STD_LOGIC;
        branch : OUT STD_LOGIC;
        memRead : OUT STD_LOGIC;
        memToReg : OUT STD_LOGIC;
        aluOp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        memWrite : OUT STD_LOGIC;
        aluSrc : OUT STD_LOGIC;
        regWrite : OUT STD_LOGIC;
        branchNotEq : OUT STD_LOGIC
    ); 
END controlLogicUnit;

ARCHITECTURE rtl OF controlLogicUnit IS
    SIGNAL r_type, lw, sw, beq, bne, jmp : STD_LOGIC;

begin
    -- determine type of instruction:
    r_type <= NOT opcode(5) AND NOT opcode(4) AND NOT opcode(3) AND NOT opcode(2) AND NOT opcode(1) AND NOT opcode(0); -- "000000"
    lw <= opcode(5) AND (NOT opcode(4)) AND (NOT opcode(3)) AND (NOT opcode(2)) AND opcode(1) AND opcode(0); -- "100011"
    sw <= opcode(5) AND (NOT opcode(4)) AND opcode(3) AND (NOT opcode(2)) AND opcode(1) AND opcode(0); -- "101011"
    beq <= NOT opcode(5) AND (NOT opcode(4)) AND (NOT opcode(3)) AND opcode(2) AND (NOT opcode(1)) AND (NOT opcode(0)); -- "000100"
    bne <= NOT opcode(5) AND (NOT opcode(4)) AND (NOT opcode(3)) AND opcode(2) AND (NOT opcode(1)) AND  opcode(0); -- "000101"
    jmp <= NOT opcode(5) AND (NOT opcode(4)) AND (NOT opcode(3)) AND (NOT opcode(2)) AND opcode(1) AND (NOT opcode(0)); -- "000010"

    -- assign outputs
    regDst <= r_type;
    aluSrc <= lw OR sw;
    memToReg <= lw;
    regWrite <= r_type OR lw;
    memRead <= lw;
    memWrite <= sw;
    aluOp(1) <= r_type;
    aluOp(0) <= beq OR bne; 
    jump <= jmp;
    branch <= beq;
    branchNotEq <= bne;
END rtl;