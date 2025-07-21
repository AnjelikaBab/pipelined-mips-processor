library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ForwardingUnit2 is
    port (
        ID_rs           : in  std_logic_vector(4 downto 0);
        ID_rt           : in  std_logic_vector(4 downto 0);
        IDEX_rs         : in  std_logic_vector(4 downto 0);
        IDEX_rt         : in  std_logic_vector(4 downto 0);
        EXMEM_rd        : in  std_logic_vector(4 downto 0);
        MEMWB_rd        : in  std_logic_vector(4 downto 0);
        EXMEM_RegWrite  : in  std_logic;
        MEMWB_RegWrite  : in  std_logic;
        ForwardA        : out std_logic_vector(1 downto 0);
        ForwardB        : out std_logic_vector(1 downto 0);
        ForwardC        : out std_logic;
        ForwardD        : out std_logic
    );
end entity;

architecture Structural of ForwardingUnit2 is

    component nbitcomparator
        generic (n : integer := 5);
        port (
            i_A, i_B       : in  std_logic_vector(n-1 downto 0);
            o_AeqB         : out std_logic;
            o_AgtB, o_AltB : out std_logic
        );
    end component;

    -- signals for equality outputs
    signal eq_EXMEM_IDEX_rs, eq_MEMWB_IDEX_rs : std_logic;
    signal eq_EXMEM_IDEX_rt, eq_MEMWB_IDEX_rt : std_logic;
    signal eq_EXMEM_ID_rt, eq_EXMEM_ID_rs     : std_logic;

begin

    -- Comparators for ForwardA
    cmp_EXMEM_IDEX_rs: nbitcomparator
        port map(i_A => EXMEM_rd, i_B => IDEX_rs, o_AeqB => eq_EXMEM_IDEX_rs, o_AgtB => open, o_AltB => open);

    cmp_MEMWB_IDEX_rs: nbitcomparator
        port map(i_A => MEMWB_rd, i_B => IDEX_rs, o_AeqB => eq_MEMWB_IDEX_rs, o_AgtB => open, o_AltB => open);

    -- Comparators for ForwardB
    cmp_EXMEM_IDEX_rt: nbitcomparator
        port map(i_A => EXMEM_rd, i_B => IDEX_rt, o_AeqB => eq_EXMEM_IDEX_rt, o_AgtB => open, o_AltB => open);

    cmp_MEMWB_IDEX_rt: nbitcomparator
        port map(i_A => MEMWB_rd, i_B => IDEX_rt, o_AeqB => eq_MEMWB_IDEX_rt, o_AgtB => open, o_AltB => open);

    -- Comparators for ForwardC and ForwardD
    cmp_EXMEM_ID_rt: nbitcomparator
        port map(i_A => EXMEM_rd, i_B => ID_rt, o_AeqB => eq_EXMEM_ID_rt, o_AgtB => open, o_AltB => open);

    cmp_EXMEM_ID_rs: nbitcomparator
        port map(i_A => EXMEM_rd, i_B => ID_rs, o_AeqB => eq_EXMEM_ID_rs, o_AgtB => open, o_AltB => open);

    --output logic 
    ForwardA <= "10" when (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and eq_EXMEM_IDEX_rs = '1') else
                "01" when (MEMWB_RegWrite = '1' and MEMWB_rd /= "00000" and eq_MEMWB_IDEX_rs = '1') else
                "00";

    
    ForwardB <= "10" when (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and eq_EXMEM_IDEX_rt = '1') else
                "01" when (MEMWB_RegWrite = '1' and MEMWB_rd /= "00000" and eq_MEMWB_IDEX_rt = '1') else
                "00";

   
    ForwardC <= '1' when (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and eq_EXMEM_ID_rt = '1') else '0';

    
    ForwardD <= '1' when (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and eq_EXMEM_ID_rs = '1') else '0';

end architecture;
