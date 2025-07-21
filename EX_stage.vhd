library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX_stage is
    port (
        clk         : in  std_logic;
        resetBar    : in  std_logic;
        load        : in  std_logic;

        -- Inputs from IDEX pipeline register
        IDEX_i_readData1   : in std_logic_vector(31 downto 0);
        IDEX_i_readData2   : in std_logic_vector(31 downto 0);
        IDEX_i_signExtImm  : in std_logic_vector(31 downto 0);
        IDEX_i_rd          : in std_logic_vector(4 downto 0);
        IDEX_i_rs          : in std_logic_vector(4 downto 0);
        IDEX_i_rt          : in std_logic_vector(4 downto 0);

        IDEX_i_aluOp       : in std_logic_vector(1 downto 0);
        IDEX_i_aluSrc      : in std_logic;
        IDEX_i_regDst      : in std_logic;

        IDEX_i_branch_taken    : in std_logic;
        IDEX_i_memRead     : in std_logic;
        IDEX_i_memWrite    : in std_logic;
        IDEX_i_regWrite    : in std_logic;
        IDEX_i_memToReg    : in std_logic;


        -- Forwarded data from EXMEM and MEMWB
        ForwardA_EXMEM     : in std_logic_vector(31 downto 0);
        ForwardA_MEMWB     : in std_logic_vector(31 downto 0);
        ForwardB_EXMEM     : in std_logic_vector(31 downto 0);
        ForwardB_MEMWB     : in std_logic_vector(31 downto 0);

        ForwardA_sel       : in std_logic_vector(1 downto 0);
        ForwardB_sel       : in std_logic_vector(1 downto 0);

        -- ALU control output
        funcCode           : in std_logic_vector(5 downto 0);

        -- Outputs to EXMEM
        EXMEM_o_aluResult  : out std_logic_vector(31 downto 0);
        EXMEM_o_writeData  : out std_logic_vector(31 downto 0);
        EXMEM_o_destReg    : out std_logic_vector(4 downto 0);

        EXMEM_o_branch     : out std_logic;
        EXMEM_o_memRead    : out std_logic;
        EXMEM_o_memWrite   : out std_logic;
        EXMEM_o_regWrite   : out std_logic;
        EXMEM_o_memToReg   : out std_logic;

        -- Hazard 
        IDEX_branch_taken : out std_logic;
        IDEX_rt : out std_logic_vector(4 downto 0);
        IDEX_rs : out std_logic_vector(4 downto 0);
        IDEX_rd : out std_logic_vector(4 downto 0);
    );
end EX_stage;

architecture Structural of EX_stage is

    -- Components
    component IDEX_reg
         port (
            IDEX_clk          : in  std_logic;
            IDEX_resetBar     : in  std_logic;
            IDEX_load         : in  std_logic;

            -- Data inputs
            IDEX_i_readData1  : in  std_logic_vector(31 downto 0);
            IDEX_i_readData2  : in  std_logic_vector(31 downto 0);
            IDEX_i_signExtImm : in  std_logic_vector(31 downto 0);
            IDEX_i_rd         : in  std_logic_vector(4 downto 0);
            IDEX_i_rs         : in std_logic_vector(4 downto 0);
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
            IDEX_o_pcPlus4    : out std_logic_vector(31 downto 0);
            IDEX_o_readData1  : out std_logic_vector(31 downto 0);
            IDEX_o_readData2  : out std_logic_vector(31 downto 0);
            IDEX_o_signExtImm : out std_logic_vector(31 downto 0);
            IDEX_o_rd         : out std_logic_vector(4 downto 0);
            IDEX_o_rs         : out std_logic_vector(4 downto 0);
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
    end component;

    component ALU
        port (
            a, b      : in std_logic_vector(31 downto 0);
            ALUOp     : in std_logic_vector(3 downto 0);
            Result    : out std_logic_vector(31 downto 0);
            Zero      : out std_logic;
            Overflow  : out std_logic;
            CarryOut  : out std_logic
        );
    end component;

    component ALU_control
        port (
            aluOP    : in std_logic_vector(1 downto 0);
            funcCode : in std_logic_vector(5 downto 0);
            operation: out std_logic_vector(2 downto 0)
        );
    end component;

    component nbitmux41
        generic (n : integer := 32);
        port (
            s0, s1   : in std_logic;
            x0, x1,
            x2, x3   : in std_logic_vector(n-1 downto 0);
            y        : out std_logic_vector(n-1 downto 0)
        );
    end component;

    component nbitmux21
        generic (n : integer := 32);
        port (
            s        : in std_logic;
            x0, x1   : in std_logic_vector(n-1 downto 0);
            y        : out std_logic_vector(n-1 downto 0)
        );
    end component;

    -- Internal signals
    signal id_pcPlus4    : std_logic_vector(31 downto 0);
    signal id_readData1  : std_logic_vector(31 downto 0);
    signal id_readData2  : std_logic_vector(31 downto 0);
    signal id_signExtImm : std_logic_vector(31 downto 0);
    signal id_rt         : std_logic_vector(4 downto 0);
    signal id_rs         : std_logic_vector(4 downto 0);
    signal id_rd         : std_logic_vector(4 downto 0);

    signal id_aluOp      : std_logic_vector(1 downto 0);
    signal id_aluSrc     : std_logic;
    signal id_regDst     : std_logic;

    signal id_branch     : std_logic;
    signal id_memRead    : std_logic;
    signal id_memWrite   : std_logic;
    signal id_regWrite   : std_logic;
    signal id_memToReg   : std_logic;

    signal aluControl    : std_logic_vector(2 downto 0);
    signal aluOp_full    : std_logic_vector(3 downto 0);

    signal alu_inputA    : std_logic_vector(31 downto 0);
    signal alu_inputB    : std_logic_vector(31 downto 0);
    signal reg_write_data: std_logic_vector(31 downto 0);

    signal alu_result    : std_logic_vector(31 downto 0);
    signal zeroFlag      : std_logic;
    signal ovfFlag       : std_logic;
    signal carryOut      : std_logic;

    signal writeReg      : std_logic_vector(4 downto 0);

begin

    -- Instantiate IDEX pipeline register
    id_ex: IDEX_reg
        port map (
            IDEX_clk          => clk,
            IDEX_resetBar     => resetBar,
            IDEX_load         => load,

            -- Data inputs
            IDEX_i_readData1  => IDEX_i_readData1,
            IDEX_i_readData2  => IDEX_i_readData2,
            IDEX_i_signExtImm => IDEX_i_signExtImm,
            IDEX_i_rd         => IDEX_i_rd,
            IDEX_i_rs         => IDEX_i_rs,
            IDEX_i_rt         => IDEX_i_rt,

            -- Control inputs
            IDEX_i_aluOp      => IDEX_i_aluOp,
            IDEX_i_aluSrc     => IDEX_i_aluSrc,
            IDEX_i_regDst     => IDEX_i_regDst,

            IDEX_i_branch     => IDEX_i_branch,
            IDEX_i_memRead    => IDEX_i_memRead,
            IDEX_i_memWrite   => IDEX_i_memWrite,
            IDEX_i_regWrite   => IDEX_i_regWrite,
            IDEX_i_memToReg   => IDEX_i_memToReg,

            -- Data outputs (internal signals)
            IDEX_o_pcPlus4    => id_pcPlus4,
            IDEX_o_readData1  => id_readData1,
            IDEX_o_readData2  => id_readData2,
            IDEX_o_signExtImm => id_signExtImm,
            IDEX_o_rd         => id_rd,
            IDEX_o_rs         => id_rs,
            IDEX_o_rt         => id_rt,

            -- Control outputs
            IDEX_o_aluOp      => id_aluOp,
            IDEX_o_aluSrc     => id_aluSrc,
            IDEX_o_regDst     => id_regDst,

            IDEX_o_branch     => id_branch,
            IDEX_o_memRead    => id_memRead,
            IDEX_o_memWrite   => id_memWrite,
            IDEX_o_regWrite   => id_regWrite,
            IDEX_o_memToReg   => id_memToReg
        );

    -- ALU Control
    alu_ctrl: ALU_control
        port map (
            aluOP     => id_aluOp,
            funcCode  => funcCode,
            operation => aluControl
        );

    aluOp_full <= '0' & aluControl;  -- Extend to 4-bit


    -- Forwarding MUX for input A
    muxA: nbitmux41
        generic map (n => 32)
        port map (
            s0 => ForwardA_sel(0),
            s1 => ForwardA_sel(1),
            x0 => id_readData1,     -- no forwarding
            x1 => ForwardA_EXMEM,   -- forward from EX/MEM
            x2 => ForwardA_MEMWB,   -- forward from MEM/WB
            x3 => (others => '0'),
            y  => alu_inputA
        );


    -- Forwarding MUX for input B
    muxB: nbitmux41
        generic map (n => 32)
        port map (
            s0 => ForwardB_sel(0),
            s1 => ForwardB_sel(1),
            x0 => id_readData2,     -- no forwarding
            x1 => ForwardB_EXMEM,   -- forward from EX/MEM
            x2 => ForwardB_MEMWB,   -- forward from MEM/WB
            x3 => (others => '0'),
            y  => reg_write_data
        );


    -- -- ALU Src MUX
    aluSrc_mux: nbitmux21
        generic map (n => 32)
        port map (
            s  => id_aluSrc,
            x0 => reg_write_data,
            x1 => id_signExtImm,
            y  => alu_inputB
        );

    -- ALU
    alu_unit: ALU
        port map (
            a        => alu_inputA,
            b        => alu_inputB,
            ALUOp    => aluOp_full,
            Result   => alu_result,
            Zero     => zeroFlag,
            Overflow => ovfFlag,
            CarryOut => carryOut
        );

    -- Write register MUX
    regDst_mux: nbitmux21
        generic map (n => 5)
        port map (
            s  => id_regDst,
            x0 => id_rt,
            x1 => id_rd,
            y  => writeReg
        );

    -- Outputs to EXMEM
    EXMEM_o_aluResult <= alu_result;
    EXMEM_o_writeData <= reg_write_data;
    EXMEM_o_destReg   <= writeReg;

    EXMEM_o_branch    <= id_branch;
    EXMEM_o_memRead   <= id_memRead;
    EXMEM_o_memWrite  <= id_memWrite;
    EXMEM_o_regWrite  <= id_regWrite;
    EXMEM_o_memToReg  <= id_memToReg;

    IDEX_rt <= id_rt;
    IDEX_rs <= id_rs;
    IDEX_rd <= id_rd;
    IDEX_branch_taken <= id_branch;

end Structural;
