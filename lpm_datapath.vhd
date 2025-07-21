-- This entity is a datapath that uses the LPM_ROM and LPM_RAM_DQ modules
-- The board itself does not support using the LPM modules for asynchronous reading so this code cannot be synthesized
-- To the Cyclone IV E boards in the lab, however this code was tested in ModelSim

library ieee;
use ieee.std_logic_1164.all;

Library lpm; -- required for all lpm functions
use lpm.lpm_components.all;

ENTITY lpm_datapath IS
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
        OpCode: Out STD_LOGIC_VECTOR(5 DOWNTO 0); -- 6-bit opcode
        FuncCode: OUT STD_LOGIC_VECTOR(5 DOWNTO 0) -- function code for r-type
    );
END lpm_datapath;

ARCHITECTURE rtl OF lpm_datapath IS
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
    
    component LPM_ROM
        generic (LPM_WIDTH : natural;    -- MUST be greater than 0
                LPM_WIDTHAD : natural;    -- MUST be greater than 0
                LPM_NUMWORDS : natural := 0;
                LPM_ADDRESS_CONTROL : string := "REGISTERED";
                LPM_OUTDATA : string := "REGISTERED";
                LPM_FILE : string;
                LPM_TYPE : string := "L_ROM";
                INTENDED_DEVICE_FAMILY  : string := "UNUSED";
                LPM_HINT : string := "UNUSED"
        );
        port (ADDRESS : in STD_LOGIC_VECTOR(LPM_WIDTHAD-1 downto 0);
            INCLOCK : in STD_LOGIC := '0';
            OUTCLOCK : in STD_LOGIC := '0';
            MEMENAB : in STD_LOGIC := '1';
            Q : out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0)
        );
    end component;

    component LPM_RAM_DQ
        generic (LPM_WIDTH : natural;    -- MUST be greater than 0
                 LPM_WIDTHAD : natural;    -- MUST be greater than 0
                 LPM_NUMWORDS : natural := 0;
                 LPM_INDATA : string := "REGISTERED";
                 LPM_ADDRESS_CONTROL: string := "REGISTERED";
                 LPM_OUTDATA : string := "REGISTERED";
                 LPM_FILE : string := "UNUSED";
                 LPM_TYPE : string := "L_RAM_DQ";
                 USE_EAB  : string := "ON";
                 INTENDED_DEVICE_FAMILY  : string := "UNUSED";
                 LPM_HINT : string := "UNUSED");
        port (DATA : in std_logic_vector(LPM_WIDTH-1 downto 0);
                ADDRESS : in std_logic_vector(LPM_WIDTHAD-1 downto 0);
                INCLOCK : in std_logic := '0';
                OUTCLOCK : in std_logic := '0';
                WE : in std_logic;
                Q : out std_logic_vector(LPM_WIDTH-1 downto 0)
        );
    end component;

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

    mem: LPM_ROM
        generic map (
            LPM_WIDTH => 32,
            LPM_WIDTHAD => 8,
            LPM_NUMWORDS => 256,
            LPM_ADDRESS_CONTROL => "UNREGISTERED",
            LPM_OUTDATA => "UNREGISTERED",
            --LPM_FILE => "C:\Users\Arnav\Desktop\Single-Cycle-MIPS\Project\testInstructionMem.mif"
            LPM_FILE => "C:\Users\Arnav\Desktop\Single-Cycle-MIPS\Project\instructionMem.mif"
        )
        port map (
            ADDRESS => pcOut(7 DOWNTO 0),
			INCLOCK => clk,
            Q => instruction
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
            Reg0_out => open,
            Reg1_out => open,
            Reg2_out => open,
            Reg3_out => open,
            Reg4_out => open,
            Reg5_out => open,
            Reg6_out => open,
            Reg7_out => open
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
    dataMem: LPM_RAM_DQ
        generic map (
            LPM_WIDTH => 32,
            LPM_WIDTHAD => 8,
            LPM_NUMWORDS => 256,
            LPM_INDATA => "UNREGISTERED",
            LPM_ADDRESS_CONTROL => "UNREGISTERED",
            LPM_OUTDATA => "UNREGISTERED",
            LPM_FILE => "C:\Users\Arnav\Desktop\Single-Cycle-MIPS\Project\dataMem.mif" -- file path is machine dependent
            -- must have complete file path to mif file for modelsim
        )
        port map (
            DATA => readData2,
            ADDRESS => alu_out(7 DOWNTO 0),
            WE => MemWrite,
            Q => memory_out
        );
end rtl;