library ieee;
use ieee.std_logic_1164.all;

entity ID_stage is
    port (
        clk, reset : in std_logic;
        IDEX_flush: in std_logic;
        
        -- forwarded values
        ID_forwardC, ID_forwardD, : in std_logic;
        EXMEM_aluResult : in std_logic_vector(31 downto 0);
        
        -- WB stage outputs
        WB_regWrite : in std_logic;
        WB_writeData, WB_writeReg: in std_logic_vector(31 downto 0);
        
        -- IF stage outputs
        IFID_pcPlus4, IFID_instr : in std_logic_vector(31 downto 0);
        
        -- Branch/Jump signals to IF
        ID_branch, IDEX_branch_taken, ID_jump : out std_logic; -- not latched
        ID_branch_addr, ID_jump_addr : out std_logic_vector(31 downto 0);
        
        -- Outputs to EX stage
        IDEX_readData1, IDEX_readData2, IDEX_signExtImm : out std_logic_vector(31 downto 0);
        IDEX_rd, IDEX_rs, IDEX_rt : out std_logic_vector(4 downto 0);
        IDEX_aluOp : out std_logic_vector(1 downto 0);
        IDEX_aluSrc, IDEX_regDst, IDEX_memRead, IDEX_memWrite : out std_logic;
        IDEX_regWrite, IDEX_memToReg : out std_logic
    );
end ID_stage;

architecture structural of ID_stage is

    component controlLogicUnit IS
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
    END component;

    component RegFile is
        PORT(
            i_reset, i_clock: IN STD_LOGIC; -- active high asynchronous reset
            ReadReg1, ReadReg2, WriteReg: IN STD_LOGIC_VECTOR(4 downto 0);
            WriteData: IN STD_LOGIC_VECTOR(31 downto 0);
            ReadData1, ReadData2: OUT STD_LOGIC_VECTOR(31 downto 0);
            RegWrite: IN STD_LOGIC;
            Reg0_out, Reg1_out, Reg2_out, Reg3_out: OUT STD_LOGIC_VECTOR(31 downto 0);
            Reg4_out, Reg5_out, Reg6_out, Reg7_out: OUT STD_LOGIC_VECTOR(31 downto 0)
        );
    END component;

    component nbitmux21 IS
        GENERIC ( n: INTEGER := 8 );
        PORT ( s: IN STD_LOGIC ;
            x0, x1: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
            y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
    END component;

    component nBitAdderSubtractor IS
        GENERIC (n : INTEGER := 4);
        PORT(
            i_Ai, i_Bi     : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            operationFlag  : IN  STD_LOGIC;
            o_CarryOut     : OUT STD_LOGIC;
            o_overflow     : OUT STD_LOGIC;
            o_Sum          : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END component;

    COMPONENT nbitcomparator IS
        GENERIC(n : INTEGER := 4);
        PORT(
            i_A, i_B	: IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            o_AeqB, o_AgtB, o_AltB : OUT STD_LOGIC);
    END COMPONENT;

    SIGNAL i_signExtImm: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL resetBar: STD_LOGIC;
    SIGNAL control_bus, control_mux_out: STD_LOGIC_VECTOR(9 downto 0);
    SIGNAL i_readData1, i_readData2: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL branch_data1, branch_data2: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL branch_cond: STD_LOGIC;
begin
    resetBar <= not i_reset;

    -- Control Logic
    controlUnit: controlLogicUnit PORT MAP(
        opcode => IFID_instr(31 downto 26),
        regDst => control_bus(9),
        jump =>control_bus(8),
        branch =>control_bus(7),
        memRead =>control_bus(6),
        memToReg =>control_bus(5),
        aluOp =>control_bus(4 downto 3),
        memWrite =>control_bus(2),
        aluSrc =>control_bus(1),
        regWrite =>control_bus(0),
        branchNotEq => open
    );

    control_mux: nbitmux21 
        GENERIC MAP(n => 10)
        PORT MAP(
            s => IDEX_flush,
            x0 => control_bus,
            x1 => (others => '0'),
            y => control_mux_out
        );

    IDEX_aluOp <= control_mux_out(4 downto 3)
    IDEX_aluSrc <= control_mux_out(1)
    IDEX_regDst, <= control_mux_out(9)
    IDEX_memRead <= control_mux_out(6)
    IDEX_memWrite <= control_mux_out(2)
    IDEX_regWrite <= control_mux_out(0)
    IDEX_memToReg <= control_mux_out(5)

    ID_branch <= control_bus(7);
    ID_jump <= control_bus(8);
    
    -- Register File
    registerFile: RegFile PORT MAP(
        i_reset => reset,
        i_clock => clk,
        ReadReg1 => IFID_instr(25 downto 21), --rs
        ReadReg2 => IFID_instr(20 downto 16), --rt
        WriteReg => WB_writeReg,
        WriteData => WB_writeData,
        ReadData1 => i_readData1,
        ReadData2 => i_readData2,
        RegWrite => WB_regWrite,
        Reg0_out => open,
        Reg1_out => open,
        Reg2_out => open,
        Reg3_out => open,
        Reg4_out => open,
        Reg5_out => open,
        Reg6_out => open,
        Reg7_out => open
    );

    -- Sign extend immediate value
    i_signExtImm <= (31 DOWNTO 16 => instruction(15)) & instruction(15 DOWNTO 0);
    
    -- Next address logic
    branch_offset <= i_signExtImm(29 DOWNTO 0) & "00";
    ID_jump_addr <= IFID_pcPlus4(31 DOWNTO 28) & i_signExtImm(25 DOWNTO 0) & "00";
    
    -- calculate branch address
    branch_adder: nBitAdderSubtractor 
        GENERIC MAP(n => 32)
        PORT MAP(
            i_Ai => IFID_pcPlus4,
            i_Bi => branch_offset,
            operationFlag => '0',
            o_CarryOut => open,
            o_overflow => open,
            o_Sum => ID_branch_addr
        );

    -- check if branch condition is met
    -- but first forward values from MEM if needed
    fwd_mux1: nbitmux21 
        GENERIC MAP(n => 32)
        PORT MAP(
            s => ID_forwardD,
            x0 => i_readData1,
            x1 => EXMEM_aluResult,
            y => branch_data1
        );

    fwd_mux2: nbitmux21
        GENERIC MAP(n => 32)
        PORT MAP(
            s => ID_forwardC,
            x0 => i_readData2,
            x1 => EXMEM_aluResult,
            y => branch_data2
        );

    branch_comp: nbitcomparator 
        GENERIC MAP(n => 32)
        PORT MAP(
            i_A => branch_data1,
            i_B => branch_data2,
            o_AeqB => branch_cond,
            o_AgtB => open,
            o_AltB => open
        );
    
    IDEX_branch_taken <= control_bus(7) and branch_cond;
    IDEX_readData1 <= i_readData1;
    IDEX_readData2 <= i_readData2;
    IDEX_signExtImm <= i_signExtImm;
    IDEX_rd <= IFID_instr(15 downto 11);
    IDEX_rs <= IFID_instr(25 downto 21);
    IDEX_rt <= IFID_instr(20 downto 16);

end structural;