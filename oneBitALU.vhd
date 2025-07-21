LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY oneBitALU IS
    PORT (
        a, b, less: IN STD_LOGIC;
        Ainvert, Binvert, CarryIn: IN STD_LOGIC;
        Operation: IN STD_LOGIC_VECTOR(1 downto 0);
        Result, Set, CarryOut: OUT STD_LOGIC
    );
END oneBitALU;

ARCHITECTURE structural OF oneBitALU IS
    SIGNAL invertedA, invertedB, sum_ab: STD_LOGIC;
    SIGNAL or_out, and_out: STD_LOGIC;

    COMPONENT mux41 IS
        PORT (s0, s1, x0, x1, x2, x3: IN STD_LOGIC ;
            y: OUT STD_LOGIC) ;
    END COMPONENT;

    COMPONENT oneBitAdderSubtractor IS
        PORT(
            i_CarryIn       : IN  STD_LOGIC;
            operationFlag   : IN  STD_LOGIC; -- 0 for addition, 1 for subtraction
            i_Ai, i_Bi      : IN  STD_LOGIC;
            o_Sum, o_CarryOut : OUT STD_LOGIC);
    END COMPONENT;
begin
    invertedA <= a xor Ainvert;
    invertedB <= b xor Binvert;

    or_out <= invertedA or invertedB;
    and_out <= invertedA and invertedB;

    adder: oneBitAdderSubtractor
        PORT MAP (
            i_CarryIn => CarryIn,
            operationFlag => '0', -- 0 for addition
            i_Ai => invertedA,
            i_Bi => invertedB,
            o_Sum => sum_ab,
            o_CarryOut => CarryOut
        );

    output_mux: mux41
        PORT MAP (
            s0 => Operation(0),
            s1 => Operation(1),
            x0 => and_out,          -- Addition result
            x1 => or_out,          -- OR result
            x2 => sum_ab,         -- AND result
            x3 => less,             -- Less than flag
            y => Result
        );

    set <= sum_ab;

end structural;