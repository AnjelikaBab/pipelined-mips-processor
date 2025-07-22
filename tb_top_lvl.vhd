LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_top_lvl IS
END tb_top_lvl;

ARCHITECTURE tb OF tb_top_lvl IS

    -- Component under test
    component pipelinedTopLvl is
        port (
            clk, reset : in std_logic
        );
    end component;

    -- Testbench signals
    SIGNAL clk_tb   : STD_LOGIC := '0';
    SIGNAL reset_tb : STD_LOGIC := '0';

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: pipelinedTopLvl
        PORT MAP (
            clk   => clk_tb,
            reset => reset_tb
        );

    -- One-line clock generator (10 ns period)
    clk_tb <= NOT clk_tb AFTER 5 ns;

    -- Reset process
    stim_proc: PROCESS
    BEGIN
        -- Initial reset
        reset_tb <= '1';
        WAIT FOR 10 ns;
        reset_tb <= '0';

        -- Let simulation run
        WAIT;
    END PROCESS;

END tb;