library ieee;
use ieee.std_logic_1164.all;

entity IFID_reg is
    port (
        IFID_clk        : in  std_logic;
        IFID_resetBar   : in  std_logic;
        IFID_load       : in  std_logic;

        IFID_i_pcPlus4  : in  std_logic_vector(31 downto 0);
        IFID_i_instr    : in  std_logic_vector(31 downto 0);

        IFID_o_pcPlus4  : out std_logic_vector(31 downto 0);
        IFID_o_instr    : out std_logic_vector(31 downto 0)
    );
end IFID_reg;

architecture Structural of IFID_reg is
    component nBitRegister
        generic (n : integer := 32);
        port (
            i_resetBar : in  std_logic;
            i_load     : in  std_logic;
            i_clock    : in  std_logic;
            i_Value    : in  std_logic_vector(n-1 downto 0);
            o_Value    : out std_logic_vector(n-1 downto 0)
        );
    end component;
begin
    pc_reg: nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => IFID_resetBar,
            i_load     => IFID_load,
            i_clock    => IFID_clk,
            i_Value    => IFID_i_pcPlus4,
            o_Value    => IFID_o_pcPlus4
        );

    instr_reg: nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => IFID_resetBar,
            i_load     => IFID_load,
            i_clock    => IFID_clk,
            i_Value    => IFID_i_instr,
            o_Value    => IFID_o_instr
        );
end Structural;
