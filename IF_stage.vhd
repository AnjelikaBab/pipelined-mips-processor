library ieee;
use ieee.std_logic_1164.all;

entity IF_stage is
    port (
        clk, reset : in std_logic;

        -- From hazard detection unit
        IF_pc_write: in std_logic;
        IFID_flush, IFID_en : in std_logic;
        
        -- Inputs from ID stage
        ID_branch, ID_jump : in std_logic;
        ID_branch_addr, ID_jump_addr : in std_logic_vector(31 downto 0);
        
        -- Outputs to ID stage
        IFID_pcPlus4, IFID_instr : out std_logic_vector(31 downto 0)
    );
end IF_stage;

architecture structural of IF_stage is
    component IFID_reg is
        port (
            IFID_clk        : in  std_logic;
            IFID_resetBar   : in  std_logic;
            IFID_load       : in  std_logic;

            IFID_i_pcPlus4  : in  std_logic_vector(31 downto 0);
            IFID_i_instr    : in  std_logic_vector(31 downto 0);

            IFID_o_pcPlus4  : out std_logic_vector(31 downto 0);
            IFID_o_instr    : out std_logic_vector(31 downto 0)
        );
    end component;

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

    component instruction_memory is
        port (
            address   : in  std_logic_vector(7 downto 0);  -- 8-bit address (word-indexed)
            instr_out : out std_logic_vector(31 downto 0)
        );
    end component;

    component nBitRegister IS
        GENERIC(n : INTEGER := 8);
        PORT(
            i_resetBar, i_load	: IN	STD_LOGIC;
            i_clock			: IN	STD_LOGIC;
            i_Value			: IN	STD_LOGIC_VECTOR(n-1 downto 0);
            o_Value			: OUT	STD_LOGIC_VECTOR(n-1 downto 0)
        );
    END component;

    SIGNAL jump_mux_out : std_logic_vector(31 downto 0);
    SIGNAL PC_in, PC_out, i_pcPlus4 : std_logic_vector(31 downto 0);
    SIGNAL i_IFID_instr : std_logic_vector(31 downto 0);
    SIGNAL resetBar : std_logic;
    SIGNAL IFID_reset: std_logic;
begin
    resetBar <= not reset;
    IFID_reset <= not (reset or IFID_flush);
    
    jump_mux: nbitmux21
        generic map (n => 32)
        port map (
            s => ID_jump,
            x0 => i_pcPlus4,
            x1 => ID_jump_addr,
            y => jump_mux_out
        );

    branch_mux: nbitmux21
        generic map (n => 32)
        port map (
            s => ID_branch,
            x0 => jump_mux_out,
            x1 => ID_branch_addr,
            y => PC_in
        );

    PC_reg: nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => resetBar,
            i_load     => IF_pc_write,
            i_clock    => clk,
            i_Value    => PC_in,
            o_Value    => PC_out
        );

    PC_adder: nBitAdderSubtractor
        generic map (n => 32)
        port map (
            i_Ai => PC_out,
            i_Bi => x"00000004",
            operationFlag => '0',
            o_CarryOut => open,
            o_overflow => open,
            o_Sum => i_pcPlus4
    );

    instr_mem: instruction_memory
        port map (
            address => PC_out(7 downto 0),
            instr_out => i_IFID_instr
        );

    IFID_reg_inst: IFID_reg
        port map (
            IFID_clk => clk,
            IFID_resetBar => IFID_reset,
            IFID_load => IFID_en,
            IFID_i_pcPlus4 => i_pcPlus4,
            IFID_i_instr => i_IFID_instr,
            IFID_o_pcPlus4 => IFID_pcPlus4,
            IFID_o_instr => IFID_instr
        );
        
end structural;
    