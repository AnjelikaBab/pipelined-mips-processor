LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY nbitmux81 IS
    GENERIC ( n: INTEGER := 8 ) ;
    PORT (s0, s1, s2: IN STD_LOGIC ;
        x0, x1, x2, x3: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
        x4, x5, x6, x7: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
        y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
END nbitmux81 ;

ARCHITECTURE structural OF nbitmux81 is
    SIGNAL mux1_out: STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL mux2_out: STD_LOGIC_VECTOR(n-1 downto 0);

    COMPONENT nbitmux41
        GENERIC ( n: INTEGER := 8 ) ;
        PORT ( s0, s1: IN STD_LOGIC ;
            x0, x1, x2, x3: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
            y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
    END COMPONENT;

BEGIN
    mux1: nbitmux41 
        GENERIC MAP (n => n)
        PORT MAP (
            s0 => s0,
            s1 => s1,
            x0 => x0,
            x1 => x1,
            x2 => x2,
            x3 => x3,
            y => mux1_out
        );

    mux2: nbitmux41
        GENERIC MAP (n => n)
        PORT MAP (
            s0 => s0,
            s1 => s1,
            x0 => x4,
            x1 => x5,
            x2 => x6,
            x3 => x7,
            y => mux2_out
        );

    -- Final output based on s2
    y <= mux1_out when s2 = '0' else mux2_out;
END structural;