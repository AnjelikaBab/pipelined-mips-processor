-- This entity is a datapath that uses the LPM_ROM and LPM_RAM_DQ modules
-- The board itself does not support using the LPM modules for asynchronous reading so this code cannot be synthesized
-- To the Cyclone IV E boards in the lab, however this code was tested in ModelSim

library ieee;
use ieee.std_logic_1164.all;

ENTITY datapath IS
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
END datapath;

ARCHITECTURE rtl OF datapath IS
    COMPONENT nbitmux81 IS
        GENERIC ( n: INTEGER := 8 ) ;
        PORT (s0, s1, s2: IN STD_LOGIC ;
            x0, x1, x2, x3: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
            x4, x5, x6, x7: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
            y: OUT STD_LOGIC_VECTOR(n-1 downto 0) );
    END COMPONENT;

    COMPONENT nbitmux21 IS
        GENERIC ( n: INTEGER := 8 );
        PORT ( s: IN STD_LOGIC ;
            x0, x1: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
            y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
    END COMPONENT;

    COMPONENT nBitAdderSubtractor IS
        GENERIC (n : INTEGER := 4);
        PORT(
            i_Ai, i_Bi     : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            operationFlag  : IN  STD_LOGIC;
            o_CarryOut     : OUT STD_LOGIC;
            o_overflow     : OUT STD_LOGIC;
            o_Sum          : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    COMPONENT nBitRegister IS
        GENERIC(n : INTEGER := 8);
        PORT(
            i_resetBar, i_load	: IN	STD_LOGIC;
            i_clock			: IN	STD_LOGIC;
            i_Value			: IN	STD_LOGIC_VECTOR(n-1 downto 0);
            o_Value			: OUT	STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    COMPONENT RegFile is
        PORT(
            i_reset, i_clock: IN STD_LOGIC; -- active high asynchronous reset
            ReadReg1, ReadReg2, WriteReg: IN STD_LOGIC_VECTOR(4 downto 0);
            WriteData: IN STD_LOGIC_VECTOR(31 downto 0);
            ReadData1, ReadData2: OUT STD_LOGIC_VECTOR(31 downto 0);
            RegWrite: IN STD_LOGIC;
            Reg0_out, Reg1_out, Reg2_out, Reg3_out: OUT STD_LOGIC_VECTOR(31 downto 0);
            Reg4_out, Reg5_out, Reg6_out, Reg7_out: OUT STD_LOGIC_VECTOR(31 downto 0)
        );
    END COMPONENT;

    component ALU is
        port (
            a, b: in std_logic_vector(31 downto 0);
            ALUOp: in std_logic_vector(3 downto 0);
            Result: out std_logic_vector(31 downto 0);
            Zero: out std_logic;
            Overflow: out std_logic;
            CarryOut: out std_logic
        );
    end component;
    
    COMPONENT instruction_memory is
        port (
            address   : in  std_logic_vector(7 downto 0);  -- 8-bit address (word-indexed)
            instr_out : out std_logic_vector(31 downto 0)
        );
    end COMPONENT;

    COMPONENT dataMem is
        port (
            clk        : in  std_logic;
            write_en   : in  std_logic;
            address    : in  std_logic_vector(7 downto 0);
            write_data : in  std_logic_vector(31 downto 0);
            read_data  : out std_logic_vector(31 downto 0)
        );
    end COMPONENT;

    COMPONENT enARdFF_2 IS
        PORT(
            i_resetBar	: IN	STD_LOGIC;
            i_d		: IN	STD_LOGIC;
            i_enable	: IN	STD_LOGIC;
            i_clock		: IN	STD_LOGIC;
            o_q, o_qBar	: OUT	STD_LOGIC);
    end COMPONENT;

    SIGNAL reset_bar: STD_LOGIC;
    SIGNAL Zero: STD_LOGIC; -- zero flag, mainly helps with branching
    SIGNAL branch_sel: STD_LOGIC;
    SIGNAL pcIn, pcOut, pc_plus_4: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL instruction: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL immediate_val, branch_offset: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL jump_addr: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL branch_addr, branch_mux_out: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL writeReg: STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL readData1, readData2, writeData: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_inB, alu_out: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL memory_out: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL Reg0_out, Reg1_out, Reg2_out, Reg3_out: STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL Reg4_out, Reg5_out, Reg6_out, Reg7_out: STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
    reset_bar <= NOT reset;

    -- PC register
    pcReg: nBitRegister
        GENERIC MAP(n => 32)
        PORT MAP(
            i_resetBar => reset_bar,
            i_load => '1',
            i_clock => clk,
            i_Value => pcIn,
            o_Value => pcOut
        );

    -- Instruction memory
    -- configure ROM so that it stores 256 32 bit instructions
    -- To make single cycle work the input and output must not be registered
    OpCode <= instruction(31 DOWNTO 26);
    FuncCode <= instruction(5 DOWNTO 0);

    instruction_mem: instruction_memory
        port map (
            address => pcOut(9 DOWNTO 2),
            instr_out => instruction
        );

    -- Sign extend immediate value
    immediate_val <= (31 DOWNTO 16 => instruction(15)) & instruction(15 DOWNTO 0);
    
    -- Next address logic
    branch_offset <= immediate_val(29 DOWNTO 0) & "00";
    jump_addr <= pc_plus_4(31 DOWNTO 28) & immediate_val(25 DOWNTO 0) & "00";

    -- PC+4 adder
    pcAdd: nBitAdderSubtractor
        GENERIC MAP(n => 32)
        PORT MAP(
            i_Ai => pcOut,
            i_Bi => "00000000000000000000000000000100", -- add 4 to pc
            operationFlag => '0', -- add operation
            o_CarryOut => open,
            o_overflow => open,
            o_Sum => pc_plus_4
        );

    -- Adder for branch address
    branchAdd: nBitAdderSubtractor
        GENERIC MAP(n => 32)
        PORT MAP(
            i_Ai => pc_plus_4,
            i_Bi => branch_offset,
            operationFlag => '0', -- add operation
            o_CarryOut => open,
            o_overflow => open,
            o_Sum => branch_addr
        );
    
    -- branch mux
    branch_sel <= (Branch AND Zero) OR (BranchNotEq AND NOT Zero);

    branchMux: nbitmux21
        GENERIC MAP(n => 32)
        PORT MAP(
            s => branch_sel,
            x0 => pc_plus_4,
            x1 => branch_addr,
            y => branch_mux_out
        );
    
    -- Jump Mux
    jumpMux: nbitmux21
        GENERIC MAP(n => 32)
        PORT MAP(
            s => Jump,
            x0 => branch_mux_out,
            x1 => jump_addr,
            y => pcIn
        );
    
    -- Register file
    writeReg_mux: nbitmux21
        GENERIC MAP(n => 5)
        PORT MAP(
            s => RegDst,
            x0 => instruction(20 DOWNTO 16),
            x1 => instruction(15 DOWNTO 11),
            y => writeReg
        );
    
    writeData_mux: nbitmux21
        GENERIC MAP(n => 32)
        PORT MAP(
            s => MemToReg,
            x0 => alu_out,
            x1 => memory_out,
            y => writeData
        );

    reg_file: RegFile
        PORT MAP(
            i_reset => reset,
            i_clock => clk,
            ReadReg1 => instruction(25 DOWNTO 21),
            ReadReg2 => instruction(20 DOWNTO 16),
            WriteReg => writeReg,
            WriteData => writeData,
            RegWrite => RegWrite,
            ReadData1 => readData1,
            ReadData2 => readData2,
            Reg0_out => Reg0_out,
            Reg1_out => Reg1_out,
            Reg2_out => Reg2_out,
            Reg3_out => Reg3_out,
            Reg4_out => Reg4_out,
            Reg5_out => Reg5_out,
            Reg6_out => Reg6_out,
            Reg7_out => Reg7_out
        );

    out_mux: nbitmux81
        GENERIC MAP(n => 32)
        PORT MAP (
            s0 => RegSelect(0), 
            s1 => RegSelect(1),
            s2 => RegSelect(2),
            x0 => Reg0_out, 
            x1 => Reg1_out, 
            x2 => Reg2_out, 
            x3 => Reg3_out,
            x4 => Reg4_out,
            x5 => Reg5_out,
            x6 => Reg6_out,
            x7 => Reg7_out,
            y => RegisterOut
        );

    -- ALU
    alu_inB_mux: nbitmux21
        GENERIC MAP(n => 32)
        PORT MAP(
            s => ALUSrc,
            x0 => readData2,
            x1 => immediate_val,
            y => alu_inB
        );

    mips_alu: ALU
        PORT MAP(
            a => readData1,
            b => alu_inB,
            ALUOp => ALUControl,
            Result => alu_out,
            Zero => Zero,
            Overflow => open,
            CarryOut => open
        );

    -- Data memory
    -- configure RAM so that it stores 256 32 bit words
    data_mem: dataMem
        port map (
            clk => clk,
            write_en => MemWrite,
            address => alu_out(7 DOWNTO 0), 
            write_data => readData2,
            read_data => memory_out
        );
end rtl;