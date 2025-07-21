LIBRARY ieee ;
USE ieee.std_logic_1164.all;

ENTITY nbitmux21 IS
    GENERIC ( n: INTEGER := 8 );
    PORT ( s: IN STD_LOGIC ;
        x0, x1: IN STD_LOGIC_VECTOR(n-1 downto 0) ;
        y: OUT STD_LOGIC_VECTOR(n-1 downto 0) ) ;
END nbitmux21;

ARCHITECTURE structural OF nbitmux21 is
    COMPONENT mux21
        PORT (s, x0, x1: IN STD_LOGIC ;
            y: OUT STD_LOGIC) ;
    END COMPONENT ;
    
BEGIN 
    muxloop: for i in 0 to n-1 generate
        mux_n: mux21 PORT MAP (s, x0(i), x1(i), y(i));
    end generate ; 
END structural ;