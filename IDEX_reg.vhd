library ieee;
use ieee.std_logic_1164.all;

entity IDEX_reg is
    port (
        IDEX_clk          : in  std_logic;
        IDEX_resetBar     : in  std_logic;
        IDEX_load         : in  std_logic;

        -- Data inputs
        IDEX_i_readData1  : in  std_logic_vector(31 downto 0);
        IDEX_i_readData2  : in  std_logic_vector(31 downto 0);
        IDEX_i_signExtImm : in  std_logic_vector(31 downto 0);
        IDEX_i_rd         : in  std_logic_vector(4 downto 0);
        IDEX_i_rs         : in  std_logic_vector(4 downto 0);
        IDEX_i_rt         : in  std_logic_vector(4 downto 0);

        -- Control signal inputs
        IDEX_i_aluOp      : in  std_logic_vector(1 downto 0);
        IDEX_i_aluSrc     : in  std_logic;
        IDEX_i_regDst     : in  std_logic;

        IDEX_i_branch_taken     : in  std_logic;
        IDEX_i_memRead    : in  std_logic;
        IDEX_i_memWrite   : in  std_logic;

        IDEX_i_regWrite   : in  std_logic;
        IDEX_i_memToReg   : in  std_logic;

        -- Data outputs
        IDEX_o_readData1  : out std_logic_vector(31 downto 0);
        IDEX_o_readData2  : out std_logic_vector(31 downto 0);
        IDEX_o_signExtImm : out std_logic_vector(31 downto 0);
        IDEX_o_rd         : out std_logic_vector(4 downto 0);
        IDEX_o_rs         : out  std_logic_vector(4 downto 0);
        IDEX_o_rt         : out std_logic_vector(4 downto 0);

        -- Control signal outputs
        IDEX_o_aluOp      : out std_logic_vector(1 downto 0);
        IDEX_o_aluSrc     : out std_logic;
        IDEX_o_regDst     : out std_logic;

        IDEX_o_branch_taken     : out std_logic;
        IDEX_o_memRead    : out std_logic;
        IDEX_o_memWrite   : out std_logic;

        IDEX_o_regWrite   : out std_logic;
        IDEX_o_memToReg   : out std_logic
    );
end IDEX_reg;

architecture Structural of IDEX_reg is
    component nBitRegister
        generic (n : integer := 32);
        port (
            i_resetBar : in  std_logic;
            i_load     : in  std_logic;
            i_clock    : in  std_logic;
            i_Value    : in  std_logic_vector(n-1 downto 0);
            o_Value    : out std_logic_vector(n-1 downto 0)
        );
    end component;

    signal control_in  : std_logic_vector(8 downto 0);
    signal control_out : std_logic_vector(8 downto 0);

begin
    -- Put all control inputs into one vector (9 bits)
    control_in <= IDEX_i_aluOp & IDEX_i_aluSrc & IDEX_i_regDst &
                  IDEX_i_branch_taken & IDEX_i_memRead & IDEX_i_memWrite &
                  IDEX_i_regWrite & IDEX_i_memToReg;

    readData1_reg: nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => IDEX_i_readData1,
            o_Value    => IDEX_o_readData1
        );

    readData2_reg: nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => IDEX_i_readData2,
            o_Value    => IDEX_o_readData2
        );

    signExtImm_reg: nBitRegister
        generic map (n => 32)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => IDEX_i_signExtImm,
            o_Value    => IDEX_o_signExtImm
        );

    rd_reg: nBitRegister
        generic map (n => 5)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => IDEX_i_rd,
            o_Value    => IDEX_o_rd
        );

    rt_reg: nBitRegister
        generic map (n => 5)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => IDEX_i_rt,
            o_Value    => IDEX_o_rt
        );

    rs_reg: nBitRegister
        generic map (n => 5)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => IDEX_i_rs,
            o_Value    => IDEX_o_rs
        );

    -- Single control register for all 9 control bits
    control_reg: nBitRegister
        generic map (n => 9)
        port map (
            i_resetBar => IDEX_resetBar,
            i_load     => IDEX_load,
            i_clock    => IDEX_clk,
            i_Value    => control_in,
            o_Value    => control_out
        );

    --control outputs
    IDEX_o_aluOp    <= control_out(8 downto 7);
    IDEX_o_aluSrc   <= control_out(6);
    IDEX_o_regDst   <= control_out(5);

    IDEX_o_branch_taken   <= control_out(4);
    IDEX_o_memRead  <= control_out(3);
    IDEX_o_memWrite <= control_out(2);

    IDEX_o_regWrite <= control_out(1);
    IDEX_o_memToReg <= control_out(0);

end Structural;
