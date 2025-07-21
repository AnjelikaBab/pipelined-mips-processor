library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ForwardingUnit is
    port (
        -- as soon as the registers get decoded, before it's stored in the following pipeline register
        ID_rs           : in  std_logic_vector(4 downto 0);
        ID_rt           : in  std_logic_vector(4 downto 0);

        -- stored in 2nd pipeline reg
        IDEX_rs         : in  std_logic_vector(4 downto 0);
        IDEX_rt         : in  std_logic_vector(4 downto 0);

        EXMEM_rd        : in  std_logic_vector(4 downto 0);
        MEMWB_rd        : in  std_logic_vector(4 downto 0);
        EXMEM_RegWrite  : in  std_logic;
        MEMWB_RegWrite  : in  std_logic;

        -- output and select for muxes
        ForwardA        : out std_logic_vector(1 downto 0);
        ForwardB        : out std_logic_vector(1 downto 0);
        ForwardC        : out std_logic;
        ForwardD        : out std_logic
    );
end entity;

architecture Behavioral of ForwardingUnit is
begin

    process(ID_rs, ID_rt, IDEX_rs, IDEX_rt, EXMEM_rd, MEMWB_rd, EXMEM_RegWrite, MEMWB_RegWrite)
    begin
        -- Defaults: use values from register file
        ForwardA <= "00";
        ForwardB <= "00";
        ForwardC <= '0';
        ForwardD <= '0';

        -- ForwardA
        if (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and EXMEM_rd = IDEX_rs) then
            ForwardA <= "10";
        elsif (MEMWB_RegWrite = '1' and MEMWB_rd /= "00000" and MEMWB_rd = IDEX_rs) then
            ForwardA <= "01";
        end if;

        -- ForwardB
        if (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and EXMEM_rd = IDEX_rt) then
            ForwardB <= "10";
        elsif (MEMWB_RegWrite = '1' and MEMWB_rd /= "00000" and MEMWB_rd = IDEX_rt) then
            ForwardB <= "01";
        end if;

        -- ForwardC
        if (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and EXMEM_rd = ID_rt) then
            ForwardC <= '1';
        end if;

        -- ForwardD
        if (EXMEM_RegWrite = '1' and EXMEM_rd /= "00000" and EXMEM_rd = ID_rs) then
            ForwardD <= '1';
        end if;

    end process;

end architecture;
