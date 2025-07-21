LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- only works for simulations, cannot be put on the board
entity toplvl is
    PORT(
        clk, reset : IN STD_LOGIC;
        regSelect: IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- connect to switches to choose which reg is shown
        registerOut: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
end toplvl;

architecture rtl of toplvl is
    SIGNAL RegDst: STD_LOGIC;
    SIGNAL Jump: STD_LOGIC;
    SIGNAL Branch: STD_LOGIC; 
    SIGNAL BranchNotEq: STD_LOGIC; 
    SIGNAL MemToReg: STD_LOGIC;
    SIGNAL ALUControl: STD_LOGIC_VECTOR(3 DOWNTO 0); 
    SIGNAL MemWrite: STD_LOGIC;
    SIGNAL ALUSrc: STD_LOGIC;
    SIGNAL RegWrite: STD_LOGIC;
    SIGNAL OpCode: STD_LOGIC_VECTOR(5 DOWNTO 0); 
    SIGNAL FuncCode: STD_LOGIC_VECTOR(5 DOWNTO 0);

    COMPONENT datapath IS
        PORT(
            clk, reset : IN STD_LOGIC; -- active high reset
            RegDst: IN STD_LOGIC; --Controls register that is written to 
            Jump: IN STD_LOGIC; -- high when jump instruction
            Branch: IN STD_LOGIC; -- high when beq
            BranchNotEq: IN STD_LOGIC; -- high when bne
            MemToReg: IN STD_LOGIC; -- loads data from memory to registers
            ALUControl: IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4-bit ALU control
            MemWrite: IN STD_LOGIC; -- enables writing to memory
            ALUSrc: IN STD_LOGIC; -- controls ALU input B
            RegWrite: IN STD_LOGIC; -- enables writing to registers
            RegSelect: IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- choose which register is shown on output of module
            OpCode: Out STD_LOGIC_VECTOR(5 DOWNTO 0); -- 6-bit opcode
            FuncCode: OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- function code for r-type
            RegisterOut: OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- single output register based on regSelect
        );
    END COMPONENT;

    COMPONENT control IS
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
    END COMPONENT;

BEGIN 
    datapath_unit: datapath
        PORT MAP(
            clk => clk,
            reset => reset,
            RegDst => RegDst,
            Jump => Jump,
            Branch => Branch,
            BranchNotEq => BranchNotEq,
            MemToReg => MemToReg,
            ALUControl => ALUControl,
            MemWrite => MemWrite,
            ALUSrc => ALUSrc,
            RegWrite => RegWrite,
            RegSelect => regSelect,
            OpCode => OpCode,
            FuncCode => FuncCode,
            RegisterOut => registerOut
        );

    control_unit: control
        PORT MAP(
            OpCode => OpCode,
            FuncCode => FuncCode,
            RegDst => RegDst,
            Jump => Jump,
            Branch => Branch,
            BranchNotEq => BranchNotEq,
            MemToReg => MemToReg,
            MemRead => open,
            ALUControl => ALUControl,
            MemWrite => MemWrite,
            ALUSrc => ALUSrc,
            RegWrite => RegWrite
        );
END rtl;