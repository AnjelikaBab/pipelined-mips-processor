LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY decoder38 IS
    PORT (
        input: IN STD_LOGIC_VECTOR(2 downto 0);
        output: OUT STD_LOGIC_VECTOR(7 downto 0)
    );
END decoder38;

ARCHITECTURE rtl OF decoder38 IS
BEGIN
    output(0) <= NOT input(2) AND NOT input(1) AND NOT input(0); -- 000
    output(1) <= NOT input(2) AND NOT input(1) AND input(0); -- 001
    output(2) <= NOT input(2) AND input(1) AND NOT input(0); -- 010
    output(3) <= NOT input(2) AND input(1) AND input(0); -- 011
    output(4) <= input(2) AND NOT input(1) AND NOT input(0); -- 100
    output(5) <= input(2) AND NOT input(1) AND input(0); -- 101
    output(6) <= input(2) AND input(1) AND NOT input(0); -- 110
    output(7) <= input(2) AND input(1) AND input(0); -- 111
END rtl;