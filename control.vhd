LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY control IS
    PORT(
        OpCode: IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- 6-bit opcode
        FuncCode: IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- function code for r-type
        RegDst: OUT STD_LOGIC; --Controls register that is written to 
        Jump: OUT STD_LOGIC; -- high when jump instruction
        Branch: OUT STD_LOGIC; -- high when beq
        BranchNotEq: OUT STD_LOGIC; -- high when bne
        MemToReg: OUT STD_LOGIC; -- loads data from memory to registers
        MemRead: OUT STD_LOGIC; -- enables reading from data mem
        ALUControl: OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit ALU control
        MemWrite: OUT STD_LOGIC; -- enables writing to memory
        ALUSrc: OUT STD_LOGIC; -- controls ALU input B
        RegWrite: OUT STD_LOGIC -- enables writing to registers
    );
END control;

ARCHITECTURE rtl OF control IS
    SIGNAL i_aluOp: STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL i_ALUControl: STD_LOGIC_VECTOR(2 DOWNTO 0);    

    COMPONENT ALU_control is
        PORT(
            aluOP: IN STD_LOGIC_VECTOR(1 downto 0); -- 2 bit alu op
            funcCode: IN STD_LOGIC_VECTOR(5 downto 0); -- 6 bit function code
            operation: OUT STD_LOGIC_VECTOR(2 downto 0) -- ALU control output
        ); 
    END COMPONENT;

    COMPONENT controlLogicUnit IS
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
    END COMPONENT;

BEGIN 
    control_unit: controlLogicUnit
        PORT MAP(
            opcode => OpCode,
            regDst => RegDst,
            jump => Jump,
            branch => Branch,
            memRead => MemRead,
            memToReg => MemToReg,
            aluOp => i_aluOp,
            memWrite => MemWrite,
            aluSrc => ALUSrc,
            regWrite => RegWrite,
            branchNotEq => BranchNotEq
        );

    alu_control_path: ALU_control
        PORT MAP(
            aluOP => i_aluOp,
            funcCode => FuncCode,
            operation => i_ALUControl
        );

    ALUControl <= '0' & i_ALUControl;

END rtl;