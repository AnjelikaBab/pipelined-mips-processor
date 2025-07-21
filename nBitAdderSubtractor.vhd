LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitAdderSubtractor IS
	GENERIC (n : INTEGER := 4);
	PORT(
		i_Ai, i_Bi     : IN  STD_LOGIC_VECTOR(n-1 downto 0);
		operationFlag  : IN  STD_LOGIC;
		o_CarryOut     : OUT STD_LOGIC;
		o_overflow     : OUT STD_LOGIC;
		o_Sum          : OUT STD_LOGIC_VECTOR(n-1 downto 0));
END nBitAdderSubtractor;

ARCHITECTURE rtl OF nBitAdderSubtractor IS
	SIGNAL int_Sum, int_CarryOut : STD_LOGIC_VECTOR(n-1 downto 0);

	COMPONENT oneBitAdderSubtractor
	PORT(
		i_CarryIn      : IN  STD_LOGIC;
		operationFlag  : IN  STD_LOGIC;
		i_Ai, i_Bi     : IN  STD_LOGIC;
		o_Sum, o_CarryOut : OUT STD_LOGIC);
	END COMPONENT;

BEGIN

	-- Instantiation for the least significant bit (bit 0)
	-- Carry in for the least significant bit is the operationFlag (0 for addition, 1 for 2s complement subtraction)
	add_0: oneBitAdderSubtractor
	PORT MAP (i_CarryIn => operationFlag, 
			  operationFlag => operationFlag,
			  i_Ai => i_Ai(0),
			  i_Bi => i_Bi(0),
			  o_Sum => int_Sum(0),
			  o_CarryOut => int_CarryOut(0));

	-- Instantiation for bits 1 to n - 1
	loop_add: for i in 1 to n-1 generate
		addrn: oneBitAdderSubtractor
		PORT MAP (i_CarryIn => int_CarryOut(i-1),
				  operationFlag => operationFlag,
				  i_Ai => i_Ai(i),
				  i_Bi => i_Bi(i),
				  o_Sum => int_Sum(i),
				  o_CarryOut => int_CarryOut(i));
	end generate;

	-- Output Driver
	o_Sum <= int_Sum;
	o_CarryOut <= int_CarryOut(n-1); -- Carry-out from the most significant bit
	o_overflow <= int_CarryOut(n-1) XOR int_CarryOut(n-2); -- Overflow detection for n-bit addition/subtraction

END rtl;
