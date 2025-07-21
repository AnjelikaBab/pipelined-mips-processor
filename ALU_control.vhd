LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY ALU_control is
    PORT(
        aluOP: IN STD_LOGIC_VECTOR(1 downto 0); -- 2 bit alu op
        funcCode: IN STD_LOGIC_VECTOR(5 downto 0); -- 6 bit function code
        operation: OUT STD_LOGIC_VECTOR(2 downto 0) -- ALU control output
    ); 
END ALU_control;

ARCHITECTURE rtl OF ALU_control is
BEGIN 
    -- logic circuit shown in lecture 4
    operation(2) <= aluOP(0) OR (aluOP(1) AND funcCode(1));
    operation(1) <= (NOT aluOP(1)) OR (NOT funcCode(2));
    operation(0) <= aluOP(1) AND (funcCode(3) OR funcCode(0));

end rtl;