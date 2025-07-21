library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEM_stage is
    port (
        clk          : in  std_logic;
        resetBar     : in  std_logic;
        load         : in  std_logic;

        -- Inputs from EX stage
        EXMEM_i_aluResult        : in  std_logic_vector(31 downto 0);
        EXMEM_i_writeData        : in  std_logic_vector(31 downto 0);
        EXMEM_i_destReg          : in  std_logic_vector(4 downto 0);

        EXMEM_i_branch           : in  std_logic;
        EXMEM_i_memRead          : in  std_logic;
        EXMEM_i_memWrite         : in  std_logic;
        EXMEM_i_regWrite         : in  std_logic;
        EXMEM_i_memToReg         : in  std_logic;

        -- Outputs to MEMWB stage
        MEMWB_o_aluResult        : out std_logic_vector(31 downto 0);
        MEMWB_o_memData          : out std_logic_vector(31 downto 0);
        MEMWB_o_destReg          : out std_logic_vector(4 downto 0);

        MEMWB_o_branch           : out std_logic;
        MEMWB_o_memRead          : out std_logic;
        MEMWB_o_memWrite         : out std_logic;
        MEMWB_o_regWrite         : out std_logic;
        MEMWB_o_memToReg         : out std_logic;


    );
end MEM_stage;

architecture Structural of MEM_stage is

    -- EXMEM pipeline register component
    component EXMEM_reg
        port (
            EXMEM_clk                : in  std_logic;
            EXMEM_resetBar           : in  std_logic;
            EXMEM_load               : in  std_logic;

            -- Data Inputs
            EXMEM_i_aluResult        : in  std_logic_vector(31 downto 0);
            EXMEM_i_writeData        : in  std_logic_vector(31 downto 0);
            EXMEM_i_destReg          : in  std_logic_vector(4 downto 0);

            -- Control Inputs
            EXMEM_i_branch           : in  std_logic;
            EXMEM_i_memRead          : in  std_logic;
            EXMEM_i_memWrite         : in  std_logic;
            EXMEM_i_regWrite         : in  std_logic;
            EXMEM_i_memToReg         : in  std_logic;

            -- Data Outputs
            EXMEM_o_branchTargetAddr : out std_logic_vector(31 downto 0);
            EXMEM_o_zeroFlag         : out std_logic;
            EXMEM_o_aluResult        : out std_logic_vector(31 downto 0);
            EXMEM_o_writeData        : out std_logic_vector(31 downto 0);
            EXMEM_o_destReg          : out std_logic_vector(4 downto 0);

            -- Control Outputs
            EXMEM_o_branch           : out std_logic;
            EXMEM_o_memRead          : out std_logic;
            EXMEM_o_memWrite         : out std_logic;
            EXMEM_o_regWrite         : out std_logic;
            EXMEM_o_memToReg         : out std_logic
        );
    end component;

    component dataMem
        port (
            clk        : in  std_logic;
            write_en   : in  std_logic;
            address    : in  std_logic_vector(7 downto 0);
            write_data : in  std_logic_vector(31 downto 0);
            read_data  : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Internal signals
    signal exmem_aluResult        : std_logic_vector(31 downto 0);
    signal exmem_writeData        : std_logic_vector(31 downto 0);
    signal exmem_destReg          : std_logic_vector(4 downto 0);

    signal exmem_branch           : std_logic;
    signal exmem_memRead          : std_logic;
    signal exmem_memWrite         : std_logic;
    signal exmem_regWrite         : std_logic;
    signal exmem_memToReg         : std_logic;

    signal mem_address            : std_logic_vector(7 downto 0);
    signal mem_read_data          : std_logic_vector(31 downto 0);

begin

    -- Instantiate EXMEM pipeline register
    exmem_reg_inst: EXMEM_reg
        port map (
            EXMEM_clk                => clk,
            EXMEM_resetBar           => resetBar,
            EXMEM_load               => load,

            EXMEM_i_aluResult        => EXMEM_i_aluResult,
            EXMEM_i_writeData        => EXMEM_i_writeData,
            EXMEM_i_destReg          => EXMEM_i_destReg,

            EXMEM_i_branch           => EXMEM_i_branch,
            EXMEM_i_memRead          => EXMEM_i_memRead,
            EXMEM_i_memWrite         => EXMEM_i_memWrite,
            EXMEM_i_regWrite         => EXMEM_i_regWrite,
            EXMEM_i_memToReg         => EXMEM_i_memToReg,

            EXMEM_o_aluResult        => exmem_aluResult,
            EXMEM_o_writeData        => exmem_writeData,
            EXMEM_o_destReg          => exmem_destReg,

            EXMEM_o_branch           => exmem_branch,
            EXMEM_o_memRead          => exmem_memRead,
            EXMEM_o_memWrite         => exmem_memWrite,
            EXMEM_o_regWrite         => exmem_regWrite,
            EXMEM_o_memToReg         => exmem_memToReg
        );

    -- Memory address for dataMem
    mem_address <= exmem_aluResult(7 downto 0);

    -- Instantiate Data Memory
    data_mem_inst: dataMem
        port map (
            clk        => clk,
            write_en   => exmem_memWrite,
            address    => mem_address,
            write_data => exmem_writeData,
            read_data  => mem_read_data
        );

    -- Outputs to MEMWB
    MEMWB_o_aluResult <= exmem_aluResult;
    MEMWB_o_memData   <= mem_read_data;
    MEMWB_o_destReg   <= exmem_destReg;

    MEMWB_o_branch    <= exmem_branch;
    MEMWB_o_memRead   <= exmem_memRead;
    MEMWB_o_memWrite  <= exmem_memWrite;
    MEMWB_o_regWrite  <= exmem_regWrite;
    MEMWB_o_memToReg  <= exmem_memToReg;

end Structural;
