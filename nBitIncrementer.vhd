LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY nBitIncrementer IS
    GENERIC (n : INTEGER := 3);
    PORT ( clk, reset, increment: IN STD_LOGIC;
            y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
END nBitIncrementer ;

ARCHITECTURE rtl OF nBitIncrementer is
    SIGNAL adder_out, int_reg_out: STD_LOGIC_VECTOR(n-1 downto 0);
	 SIGNAL int_Bi: STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL int_clear: STD_LOGIC;

    COMPONENT nBitAdderSubtractor
        GENERIC (n : INTEGER := 3);
        PORT(
            i_Ai, i_Bi     : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            operationFlag  : IN  STD_LOGIC;
            o_CarryOut     : OUT STD_LOGIC;
            o_Sum          : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    COMPONENT nBitRegister
        GENERIC(n : INTEGER := 3);
        PORT(
            i_resetBar, i_load    : IN  STD_LOGIC;
            i_clock             : IN  STD_LOGIC;
            i_Value             : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            o_Value             : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

BEGIN 
    adder: nBitAdderSubtractor
        GENERIC MAP (n => n)
        PORT MAP (i_Ai => int_reg_out, i_Bi => int_Bi, operationFlag => '0', o_CarryOut => open, o_Sum => adder_out);

    reg: nBitRegister
        GENERIC MAP (n => n)
        PORT MAP (i_resetBar => int_clear, i_load => increment, i_clock => clk, i_Value => adder_out, o_Value => int_reg_out);

    
	 int_Bi <= (n-1 downto 1 => '0') & '1';
	 int_clear <= not reset;

    -- Output Driver
    y <= int_reg_out;

END rtl;