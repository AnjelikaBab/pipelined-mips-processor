LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

ENTITY nbitmux41 IS
    GENERIC ( n: INTEGER := 8 ) ;
    PORT ( s0, s1: IN STD_LOGIC ;
        x0, x1, x2, x3: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
        y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
END nbitmux41 ;

ARCHITECTURE structural OF nbitmux41 is
    COMPONENT mux41
        PORT ( s0, s1: IN STD_LOGIC ;
            x0, x1, x2, x3: IN STD_LOGIC ;
            y: OUT STD_LOGIC ) ;
    END COMPONENT ;

BEGIN
    muxloop: for i in 0 to n-1 generate
        mux_n: mux41 PORT MAP (s0, s1, x0(i), x1(i), x2(i), x3(i), y(i));
    end generate ;
    
END structural ;