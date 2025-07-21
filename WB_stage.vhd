library ieee;
use ieee.std_logic_1164.all;

entity WB_stage is
    port (
        clk          : in  std_logic;
        resetBar     : in  std_logic;
        load         : in  std_logic;

        
        i_regWrite   : in  std_logic;
        i_memToReg   : in  std_logic;
        i_memData    : in  std_logic_vector(31 downto 0);
        i_aluResult  : in  std_logic_vector(31 downto 0);
        i_EXMEM_rd   : in  std_logic_vector(4 downto 0);

        
        o_writeData  : out std_logic_vector(31 downto 0);
        o_MEMWB_rd   : out std_logic_vector(4 downto 0);
        o_MEMWB_regWrite   : out std_logic
    );
end WB_stage;

architecture Structural of WB_stage is

    component MEMWB_reg
        port (
            MEMWB_clk        : in  std_logic;
            MEMWB_resetBar   : in  std_logic;
            MEMWB_load       : in  std_logic;

            MEMWB_i_regWrite : in  std_logic;
            MEMWB_i_memToReg : in  std_logic;

            MEMWB_i_memData   : in  std_logic_vector(31 downto 0);
            MEMWB_i_aluResult : in  std_logic_vector(31 downto 0);
            MEMWB_i_rd        : in  std_logic_vector(4 downto 0);

            MEMWB_o_memData   : out std_logic_vector(31 downto 0);
            MEMWB_o_aluResult : out std_logic_vector(31 downto 0);
            MEMWB_o_rd        : out std_logic_vector(4 downto 0);
            MEMWB_o_regWrite  : out std_logic;
            MEMWB_o_memToReg  : out std_logic
        );
    end component;

    component nbitmux21
        generic ( n : integer := 32 );
        port (
            s  : in  std_logic;
            x0 : in  std_logic_vector(n-1 downto 0);
            x1 : in  std_logic_vector(n-1 downto 0);
            y  : out std_logic_vector(n-1 downto 0)
        );
    end component;

    signal memwb_memData   : std_logic_vector(31 downto 0);
    signal memwb_aluResult : std_logic_vector(31 downto 0);
    signal memwb_rd        : std_logic_vector(4 downto 0);
    signal memwb_regWrite  : std_logic;
    signal memwb_memToReg  : std_logic;

begin

    -- Instantiate MEMWB pipeline register
    MEMWB_inst : MEMWB_reg
        port map (
            MEMWB_clk        => clk,
            MEMWB_resetBar   => resetBar,
            MEMWB_load       => load,

            MEMWB_i_regWrite => i_regWrite,
            MEMWB_i_memToReg => i_memToReg,

            MEMWB_i_memData   => i_memData,
            MEMWB_i_aluResult => i_aluResult,
            MEMWB_i_rd        => i_EXMEM_rd,

            MEMWB_o_memData   => memwb_memData,
            MEMWB_o_aluResult => memwb_aluResult,
            MEMWB_o_rd        => memwb_rd,
            MEMWB_o_regWrite  => memwb_regWrite,
            MEMWB_o_memToReg  => memwb_memToReg
        );

    -- Use your nbitmux21 to select write data
    mux_inst : nbitmux21
        generic map (n => 32)
        port map (
            s  => memwb_memToReg,
            x0 => memwb_aluResult,
            x1 => memwb_memData,
            y  => o_writeData
        );

    
    o_MEMWB_rd <= memwb_rd;      
    o_MEMWB_regWrite <= memwb_regWrite;

end Structural;
