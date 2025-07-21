LIBRARY ieee;
USE ieee.std_logic_1164.all;

--32 bit ALU
ENTITY ALU IS
    PORT (
        a, b: IN STD_LOGIC_VECTOR(31 downto 0);
        ALUOp: IN STD_LOGIC_VECTOR(3 downto 0);
        Result: OUT STD_LOGIC_VECTOR(31 downto 0);
        Zero: OUT STD_LOGIC;
        Overflow: OUT STD_LOGIC;
        CarryOut: OUT STD_LOGIC
    );
END ALU;

ARCHITECTURE structural OF ALU IS
    SIGNAL i_carryOut: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL less: STD_LOGIC_VECTOR(31 downto 0);
	 SIGNAL i_Result: STD_LOGIC_VECTOR(31 downto 0);
    SIGNAL set: STD_LOGIC;

    COMPONENT oneBitALU IS
        PORT (
            a, b, less: IN STD_LOGIC;
            Ainvert, Binvert, CarryIn: IN STD_LOGIC;
            Operation: IN STD_LOGIC_VECTOR(1 downto 0);
            Result, Set, CarryOut: OUT STD_LOGIC
        );
    END COMPONENT;

begin

    ALU_LSB: oneBitALU
        PORT MAP (
            a => a(0),
            b => b(0),
            less => set,
            Ainvert => ALUOp(3),
            Binvert => ALUOp(2),
            CarryIn => ALUOp(2),
            Operation => ALUOp(1 downto 0),
            Result => i_Result(0),
            Set => open,
            CarryOut => i_carryOut(0)
        );

    ALU_MSB: oneBitALU
        PORT MAP (
            a => a(31),
            b => b(31),
            less => '0', -- Connect to the previous carryOut for less than operation
            Ainvert => ALUOp(3),
            Binvert => ALUOp(2),
            CarryIn => i_carryOut(30), -- Connect to the previous carryOut
            Operation => ALUOp(1 downto 0),
            Result => i_Result(31),
            Set => set,
            CarryOut => i_carryOut(31)
        );

    -- Repeat for all other bits (1 to 30)
    ALU_Loop: FOR i IN 1 TO 30 GENERATE
        ALU_Bit: oneBitALU
            PORT MAP (
                a => a(i),
                b => b(i),
                less => '0', -- Connect to the previous carryOut for less than operation
                Ainvert => ALUOp(3),
                Binvert => ALUOp(2),
                CarryIn => i_carryOut(i - 1), -- Connect to the previous carryOut
                Operation => ALUOp(1 downto 0),
                Result => i_Result(i),
                Set => open,
                CarryOut => i_carryOut(i)
            );
    END GENERATE;

	 -- Drive Result
    Result <= i_Result;
	 
	 -- Set Flags
    Zero <= NOT(i_Result(31) or i_Result(30) or i_Result(29) or i_Result(28) or
                i_Result(27) or i_Result(26) or i_Result(25) or i_Result(24) or
                i_Result(23) or i_Result(22) or i_Result(21) or i_Result(20) or
                i_Result(19) or i_Result(18) or i_Result(17) or i_Result(16) or
                i_Result(15) or i_Result(14) or i_Result(13) or i_Result(12) or
                i_Result(11) or i_Result(10) or i_Result(9)  or i_Result(8)  or
                i_Result(7)  or i_Result(6)  or i_Result(5)  or i_Result(4)  or
                i_Result(3)  or i_Result(2)  or i_Result(1)  or i_Result(0));
                
    Overflow <= i_carryOut(31) xor i_carryOut(30); -- Example for overflow detection
    CarryOut <= i_carryOut(31); -- Final carry out from the most significant bit

END structural;