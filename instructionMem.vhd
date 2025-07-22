library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_memory is
    port (
        address   : in  std_logic_vector(7 downto 0);  -- 8-bit address (word-indexed)
        instr_out : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of instruction_memory is
    type rom_array is array (0 to 255) of std_logic_vector(31 downto 0);
    
    signal rom : rom_array := (
        -- Preloaded Instructions (word-aligned)
        0  => x"8C020000", -- lw $2, 0($0)
        1  => x"8C030001", -- lw $3, 1($0)
        2  => x"00620822", -- sub $1, $3, $2
        3  => x"00232025", -- or $4, $1, $3
        4  => x"AC040003", -- sw $4, 3($0)
        5  => x"00430820", -- add $1, $2, $3
        6  => x"AC010004", -- sw $1, 4($0)
        7  => x"8C020003", -- lw $2, 3($0)
        8  => x"8C030004", -- lw $3, 4($0)
        9  => x"0800000B", -- j 0x2C (word 11)
        10 => x"1021FFF5", -- beq $1, $1, -48 (branch back)
        11 => x"1022FFFE", -- beq $1, $2, -8

        others => (others => '0')  -- unused locations default to zero
    );
begin
    instr_out <= rom(to_integer(unsigned(address)));
    -- instr_out <= (others => '0');
end architecture;