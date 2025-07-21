library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dataMem is
    port (
        clk        : in  std_logic;
        write_en   : in  std_logic;
        address    : in  std_logic_vector(7 downto 0);
        write_data : in  std_logic_vector(31 downto 0);
        read_data  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of dataMem is
    type memory_array is array (0 to 255) of std_logic_vector(31 downto 0);
    signal mem : memory_array := (
        0 => x"00000055",
        1 => x"000000AA",
        others => (others => '0')
    );
begin

    -- similar to a decoder enabling the registers
    process(clk)
    begin
        if rising_edge(clk) then
            if write_en = '1' then
                mem(to_integer(unsigned(address))) <= write_data;
            end if;
        end if;
    end process;

    -- similar to a very large multiplexer choosing the outputs
    read_data <= mem(to_integer(unsigned(address)));

end architecture;