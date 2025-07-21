LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY MEMWB_reg IS
    PORT(
        MEMWB_clk        : IN  STD_LOGIC;
        MEMWB_resetBar   : IN  STD_LOGIC;
        MEMWB_load       : IN  STD_LOGIC;

        -- Control Inputs
        MEMWB_i_regWrite : IN  std_logic;
        MEMWB_i_memToReg : IN  std_logic;

        -- Inputs from MEM stage
        MEMWB_i_memData   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        MEMWB_i_aluResult : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        MEMWB_i_rd        : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);

        -- Outputs to WB stage
        MEMWB_o_memData   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        MEMWB_o_aluResult : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        MEMWB_o_rd        : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        MEMWB_o_regWrite  : OUT STD_LOGIC;
        MEMWB_o_memToReg  : OUT STD_LOGIC
    );
END MEMWB_reg;

ARCHITECTURE Structural OF MEMWB_reg IS

    COMPONENT nBitRegister
        GENERIC(n : INTEGER := 8);
        PORT(
            i_resetBar  : IN  STD_LOGIC;
            i_load      : IN  STD_LOGIC;
            i_clock     : IN  STD_LOGIC;
            i_Value     : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            o_Value     : OUT STD_LOGIC_VECTOR(n-1 downto 0)
        );
    END COMPONENT;

    SIGNAL control_in  : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL control_out : STD_LOGIC_VECTOR(1 downto 0);

BEGIN

    -- Pack control signals into 2-bit vector
    control_in <= MEMWB_i_regWrite & MEMWB_i_memToReg;

    -- Memory Data Register
    memDataReg: nBitRegister GENERIC MAP(32)
        PORT MAP(
            i_resetBar => MEMWB_resetBar,
            i_load     => MEMWB_load,
            i_clock    => MEMWB_clk,
            i_Value    => MEMWB_i_memData,
            o_Value    => MEMWB_o_memData
        );

    -- ALU Result Register
    aluResultReg: nBitRegister GENERIC MAP(32)
        PORT MAP(
            i_resetBar => MEMWB_resetBar,
            i_load     => MEMWB_load,
            i_clock    => MEMWB_clk,
            i_Value    => MEMWB_i_aluResult,
            o_Value    => MEMWB_o_aluResult
        );

    -- RD Register (destination register number)
    rdReg: nBitRegister GENERIC MAP(5)
        PORT MAP(
            i_resetBar => MEMWB_resetBar,
            i_load     => MEMWB_load,
            i_clock    => MEMWB_clk,
            i_Value    => MEMWB_i_rd,
            o_Value    => MEMWB_o_rd
        );

    -- Control Signal Register 
    control_reg : nBitRegister
        GENERIC MAP (n => 2)
        PORT MAP (
            i_resetBar => MEMWB_resetBar,
            i_load     => MEMWB_load,
            i_clock    => MEMWB_clk,
            i_Value    => control_in,
            o_Value    => control_out
        );

    -- control signals
    MEMWB_o_regWrite <= control_out(1);
    MEMWB_o_memToReg <= control_out(0);

END Structural;
