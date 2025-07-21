library ieee;
use ieee.std_logic_1164.all;

entity EXMEM_reg is
    port (
        EXMEM_clk                : in  std_logic;
        EXMEM_resetBar           : in  std_logic;
        EXMEM_load               : in  std_logic;

        -- Data Inputs
        EXMEM_i_aluResult        : in  std_logic_vector(31 downto 0);
        EXMEM_i_writeData        : in  std_logic_vector(31 downto 0);
        EXMEM_i_destReg          : in  std_logic_vector(4 downto 0);

        -- Control Inputs
        EXMEM_i_branch           : in  std_logic;
        EXMEM_i_memRead          : in  std_logic;
        EXMEM_i_memWrite         : in  std_logic;
        EXMEM_i_regWrite         : in  std_logic;
        EXMEM_i_memToReg         : in  std_logic;

        -- Data Outputs
        EXMEM_o_aluResult        : out std_logic_vector(31 downto 0);
        EXMEM_o_writeData        : out std_logic_vector(31 downto 0);
        EXMEM_o_destReg          : out std_logic_vector(4 downto 0);

        -- Control Outputs
        EXMEM_o_branch           : out std_logic;
        EXMEM_o_memRead          : out std_logic;
        EXMEM_o_memWrite         : out std_logic;
        EXMEM_o_regWrite         : out std_logic;
        EXMEM_o_memToReg         : out std_logic
    );
end EXMEM_reg;

architecture Structural of EXMEM_reg is

    -- n-bit register component
    component nBitRegister
        generic (
            n : integer := 32
        );
        port (
            i_resetBar : in  std_logic;
            i_load     : in  std_logic;
            i_clock    : in  std_logic;
            i_Value    : in  std_logic_vector(n-1 downto 0);
            o_Value    : out std_logic_vector(n-1 downto 0)
        );
    end component;

    -- 1-bit enabled async reset D-FF
    component enARdFF_2 is
        port (
            i_resetBar : in  std_logic;
            i_d        : in  std_logic;
            i_enable   : in  std_logic;
            i_clock    : in  std_logic;
            o_q        : out std_logic;
            o_qBar     : out std_logic
        );
    end component;

    signal control_in  : std_logic_vector(4 downto 0);
    signal control_out : std_logic_vector(4 downto 0);
    signal zero_dummy  : std_logic;  -- unused o_qBar from enARdFF_2

begin

    control_in <= EXMEM_i_branch & EXMEM_i_memRead & EXMEM_i_memWrite & EXMEM_i_regWrite & EXMEM_i_memToReg;

    -- Data registers

    aluResult_reg : nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => EXMEM_resetBar,
            i_load     => EXMEM_load,
            i_clock    => EXMEM_clk,
            i_Value    => EXMEM_i_aluResult,
            o_Value    => EXMEM_o_aluResult
        );

    writeData_reg : nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => EXMEM_resetBar,
            i_load     => EXMEM_load,
            i_clock    => EXMEM_clk,
            i_Value    => EXMEM_i_writeData,
            o_Value    => EXMEM_o_writeData
        );

    destReg_reg : nBitRegister
        generic map (n => 5)
        port map (
            i_resetBar => EXMEM_resetBar,
            i_load     => EXMEM_load,
            i_clock    => EXMEM_clk,
            i_Value    => EXMEM_i_destReg,
            o_Value    => EXMEM_o_destReg
        );

    control_reg : nBitRegister
        generic map (n => 5)
        port map (
            i_resetBar => EXMEM_resetBar,
            i_load     => EXMEM_load,
            i_clock    => EXMEM_clk,
            i_Value    => control_in,
            o_Value    => control_out
        );

    -- Control outputs 
    EXMEM_o_branch   <= control_out(4);
    EXMEM_o_memRead  <= control_out(3);
    EXMEM_o_memWrite <= control_out(2);
    EXMEM_o_regWrite <= control_out(1);
    EXMEM_o_memToReg <= control_out(0);

end Structural;
