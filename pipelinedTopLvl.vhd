library ieee;
use ieee.std_logic_1164.all;

entity pipelinedTopLvl is
    port (
        clk, reset : in std_logic
    );
end pipelinedTopLvl;

architecture structural of pipelinedTopLvl is
    component IF_stage is
        port (
            clk, reset : in std_logic;

            -- From hazard detection unit
            IF_pc_write: in std_logic;
            IFID_flush, IFID_en : in std_logic;
            
            -- Inputs from ID stage
            ID_branch, ID_jump : in std_logic;
            ID_branch_addr, ID_jump_addr : in std_logic_vector(31 downto 0);
            
            -- Outputs to ID stage
            IFID_pcPlus4, IFID_instr : out std_logic_vector(31 downto 0)
        );
    end component;

    component ID_stage is
        port (
            clk, reset : in std_logic;
            IDEX_flush: in std_logic;
            
            -- forwarded values
            ID_forwardC, ID_forwardD : in std_logic;
            EXMEM_aluResult : in std_logic_vector(31 downto 0);
            
            -- WB stage outputs
            WB_regWrite : in std_logic;
            WB_writeData : in std_logic_vector(31 downto 0);
				WB_writeReg : in std_logic_vector(4 downto 0);
            
            -- IF stage outputs
            IFID_pcPlus4, IFID_instr : in std_logic_vector(31 downto 0);
            
            -- Branch/Jump signals to IF
            ID_branch, IDEX_branch_taken, ID_jump : out std_logic; -- not latched
            ID_branch_addr, ID_jump_addr : out std_logic_vector(31 downto 0);
            
            -- Outputs to EX stage
            IDEX_readData1, IDEX_readData2, IDEX_signExtImm : out std_logic_vector(31 downto 0);
            IDEX_rd, IDEX_rs, IDEX_rt : out std_logic_vector(4 downto 0);
            IDEX_aluOp : out std_logic_vector(1 downto 0);
            IDEX_aluSrc, IDEX_regDst, IDEX_memRead, IDEX_memWrite : out std_logic;
            IDEX_regWrite, IDEX_memToReg : out std_logic
        );
    end component;

    component EX_stage is
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

            IDEX_i_branch_taken      : in std_logic;
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
            IDEX_rd : out std_logic_vector(4 downto 0)
        );
    end component;

    component MEM_stage is
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
            MEMWB_o_memToReg         : out std_logic
        );
    end component;

    component WB_stage is
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
    end component;
    
    component forwarding_unit is
        port (
            -- as soon as the registers get decoded, before it's stored in the following pipeline register
            ID_rs           : in  std_logic_vector(4 downto 0);
            ID_rt           : in  std_logic_vector(4 downto 0);

            -- stored in 2nd pipeline reg
            IDEX_rs         : in  std_logic_vector(4 downto 0);
            IDEX_rt         : in  std_logic_vector(4 downto 0);

            EXMEM_rd        : in  std_logic_vector(4 downto 0);
            MEMWB_rd        : in  std_logic_vector(4 downto 0);
            EXMEM_RegWrite  : in  std_logic;
            MEMWB_RegWrite  : in  std_logic;

            -- output and select for muxes
            ForwardA        : out std_logic_vector(1 downto 0);
            ForwardB        : out std_logic_vector(1 downto 0);
            ForwardC        : out std_logic;
            ForwardD        : out std_logic
        );
    end component;

    component hazard_detection is
        port (
            -- ID
            if_id_branch: in std_logic;
            if_id_rs, if_id_rt: in std_logic_vector(4 downto 0);

            -- EX
            id_ex_mem_read, id_ex_branch_taken: in std_logic;
            id_ex_rt, id_ex_rd: in std_logic_vector(4 downto 0);
            
            -- MEM
            ex_mem_read: in std_logic;
            ex_mem_rt: in std_logic_vector(4 downto 0);
            
            -- Outputs to IF
            pc_write, if_id_en: out std_logic;
            if_id_flush: out std_logic;

            -- Ouput to ID
            id_ex_flush: out std_logic
        );
    end component;

    -- Signal declarations
    -- IF
    SIGNAL IF_pc_write: std_logic;
    SIGNAL IFID_flush, IFID_en : std_logic;
    SIGNAL ID_branch, ID_jump : std_logic;
    SIGNAL ID_branch_addr, ID_jump_addr : std_logic_vector(31 downto 0);
    
    -- ID
    SIGNAL IDEX_flush: std_logic;
    SIGNAL ID_forwardC, ID_forwardD : std_logic;
    SIGNAL EXMEM_aluResult : std_logic_vector(31 downto 0);
    SIGNAL WB_regWrite : std_logic;
    SIGNAL WB_writeData: std_logic_vector(31 downto 0);
	 SIGNAL WB_writeReg: std_logic_vector(4 downto 0);
    SIGNAL IFID_pcPlus4, IFID_instr : std_logic_vector(31 downto 0);
    
    -- EX
    SIGNAL IDEX_i_readData1   : std_logic_vector(31 downto 0);
    SIGNAL IDEX_i_readData2   : std_logic_vector(31 downto 0);
    SIGNAL IDEX_i_signExtImm  : std_logic_vector(31 downto 0);
    SIGNAL IDEX_i_rd          : std_logic_vector(4 downto 0);
    SIGNAL IDEX_i_rs          : std_logic_vector(4 downto 0);
    SIGNAL IDEX_i_rt          : std_logic_vector(4 downto 0);
    SIGNAL IDEX_i_aluOp       : std_logic_vector(1 downto 0);
    SIGNAL IDEX_i_aluSrc      : std_logic;
    SIGNAL IDEX_i_regDst      : std_logic;
    SIGNAL IDEX_i_branch_taken      : std_logic;
    SIGNAL IDEX_i_memRead     : std_logic;
    SIGNAL IDEX_i_memWrite    : std_logic;
    SIGNAL IDEX_i_regWrite    : std_logic;
    SIGNAL IDEX_i_memToReg    : std_logic;
    SIGNAL ForwardA_EXMEM     : std_logic_vector(31 downto 0);
    SIGNAL ForwardA_MEMWB     : std_logic_vector(31 downto 0);
    SIGNAL ForwardB_EXMEM     : std_logic_vector(31 downto 0);
    SIGNAL ForwardB_MEMWB     : std_logic_vector(31 downto 0);
    SIGNAL ForwardA_sel       : std_logic_vector(1 downto 0);
    SIGNAL ForwardB_sel       : std_logic_vector(1 downto 0);
    SIGNAL funcCode           : std_logic_vector(5 downto 0);

    -- MEM
    SIGNAL EXMEM_i_aluResult        :  std_logic_vector(31 downto 0);
    SIGNAL EXMEM_i_writeData        :  std_logic_vector(31 downto 0);
    SIGNAL EXMEM_i_destReg          :  std_logic_vector(4 downto 0);
    SIGNAL EXMEM_i_branch           :  std_logic;
    SIGNAL EXMEM_i_memRead          :  std_logic;
    SIGNAL EXMEM_i_memWrite         :  std_logic;
    SIGNAL EXMEM_i_regWrite         :  std_logic;
    SIGNAL EXMEM_i_memToReg         :  std_logic;

    -- WB
    SIGNAL i_regWrite   :  std_logic;
    SIGNAL i_memToReg   :  std_logic;
    SIGNAL i_memData    :  std_logic_vector(31 downto 0);
    SIGNAL i_aluResult  :  std_logic_vector(31 downto 0);
    SIGNAL i_EXMEM_rd   :  std_logic_vector(4 downto 0);

    -- forwarding unit
    SIGNAL ID_rs           :  std_logic_vector(4 downto 0);
    SIGNAL ID_rt           :  std_logic_vector(4 downto 0);
    SIGNAL IDEX_rs         :  std_logic_vector(4 downto 0);
    SIGNAL IDEX_rt         :  std_logic_vector(4 downto 0);
    SIGNAL EXMEM_rd        :  std_logic_vector(4 downto 0);
    SIGNAL MEMWB_rd        :  std_logic_vector(4 downto 0);
    SIGNAL EXMEM_RegWrite  :  std_logic;
    SIGNAL MEMWB_RegWrite  :  std_logic;
    
    -- hazard detection unit
    SIGNAL id_ex_mem_read, id_ex_branch_taken: std_logic;
    SIGNAL id_ex_rt, id_ex_rd: std_logic_vector(4 downto 0);
    SIGNAL ex_mem_read: std_logic;
    SIGNAL ex_mem_rt: std_logic_vector(4 downto 0);
    
    SIGNAL IDEX_rd: std_logic_vector(4 downto 0);	 
	 SIGNAL resetBar: std_logic;
	 SIGNAL IDEX_branch_taken: std_logic;

begin
	resetBar <= not reset;

    instr_fetch: IF_stage
        port map(
            -- inputs
            clk => clk,
            reset => reset,
            IF_pc_write => IF_pc_write,
            IFID_flush => IFID_flush,
            IFID_en => IFID_en,
            ID_branch => ID_branch,
            ID_jump => ID_jump,
            ID_branch_addr => ID_branch_addr,
            ID_jump_addr => ID_jump_addr,
            -- outputs
            IFID_pcPlus4 => IFID_pcPlus4,
            IFID_instr => IFID_instr
        );
    
    instr_decode: ID_stage
        port map(
            -- inputs
            clk => clk,
            reset => reset,
            IDEX_flush => IFID_flush,
            ID_forwardC => ID_forwardC,
            ID_forwardD => ID_forwardD,
            EXMEM_aluResult => EXMEM_aluResult,
            WB_regWrite => WB_regWrite,
            WB_writeData => WB_writeData,
            WB_writeReg => WB_writeReg,
            IFID_pcPlus4 => IFID_pcPlus4,
            IFID_instr => IFID_instr,
            -- outputs
            IDEX_readData1 => IDEX_i_readData1,
            IDEX_readData2 => IDEX_i_readData2,
            IDEX_signExtImm  => IDEX_i_signExtImm,
            IDEX_rd => IDEX_i_rd,
            IDEX_rs => IDEX_i_rs,
            IDEX_rt => IDEX_i_rt,
            IDEX_aluOp => IDEX_i_aluOp,
            IDEX_aluSrc => IDEX_i_aluSrc,
            IDEX_regDst => IDEX_i_regDst,
            IDEX_memRead => IDEX_i_memRead,
            IDEX_memWrite => IDEX_i_memWrite,
            IDEX_regWrite => IDEX_i_regWrite,
            IDEX_memToReg => IDEX_i_memToReg
        );

    exec: EX_stage
        port map(
            -- inputs
            clk => clk,
            resetBar => resetBar,
            load => '1',
            IDEX_i_readData1 => IDEX_i_readData1,
            IDEX_i_readData2 => IDEX_i_readData2,
            IDEX_i_signExtImm => IDEX_i_signExtImm,
            IDEX_i_rd => IDEX_i_rd,
            IDEX_i_rs => IDEX_i_rs,
            IDEX_i_rt => IDEX_i_rt,
            IDEX_i_aluOp => IDEX_i_aluOp,
            IDEX_i_aluSrc => IDEX_i_aluSrc,
            IDEX_i_regDst => IDEX_i_regDst,
            IDEX_i_branch_taken => IDEX_i_branch_taken,
            IDEX_i_memRead => IDEX_i_memRead,
            IDEX_i_memWrite => IDEX_i_memWrite,
            IDEX_i_regWrite => IDEX_i_regWrite,
            IDEX_i_memToReg => IDEX_i_memToReg,
            ForwardA_EXMEM => ForwardA_EXMEM,
            ForwardA_MEMWB => ForwardA_MEMWB,
            ForwardB_EXMEM => ForwardB_EXMEM,
            ForwardB_MEMWB => ForwardB_MEMWB,
            ForwardA_sel => ForwardA_sel,
            ForwardB_sel => ForwardB_sel,
            funcCode => funcCode,
            -- Outputs 
            EXMEM_o_aluResult => EXMEM_i_aluResult,
            EXMEM_o_writeData => EXMEM_i_writeData,
            EXMEM_o_destReg => EXMEM_i_destReg,
            EXMEM_o_branch => EXMEM_i_branch,
            EXMEM_o_memRead => EXMEM_i_memRead,
            EXMEM_o_memWrite => EXMEM_i_memWrite,
            EXMEM_o_regWrite => EXMEM_i_regWrite,
            EXMEM_o_memToReg => EXMEM_i_memToReg,
            IDEX_branch_taken => IDEX_branch_taken,
            IDEX_rt => IDEX_rt,
            IDEX_rs => IDEX_rs,
            IDEX_rd => IDEX_rd
        );

    memory: MEM_stage
        port map(
            -- inputs
            clk => clk,
            resetBar => resetBar,
            load => '1',
            EXMEM_i_aluResult => EXMEM_i_aluResult,
            EXMEM_i_writeData => EXMEM_i_writeData,
            EXMEM_i_destReg => EXMEM_i_destReg,
            EXMEM_i_branch => EXMEM_i_branch,
            EXMEM_i_memRead => EXMEM_i_memRead,
            EXMEM_i_memWrite => EXMEM_i_memWrite,
            EXMEM_i_regWrite => EXMEM_i_regWrite,
            EXMEM_i_memToReg => EXMEM_i_memToReg,
            -- output
            MEMWB_o_aluResult => i_aluResult,
            MEMWB_o_memData => i_memData,
            MEMWB_o_destReg => i_EXMEM_rd,
            MEMWB_o_branch => open,
            MEMWB_o_memRead => ex_mem_read,
            MEMWB_o_memWrite => open,
            MEMWB_o_regWrite => i_regWrite,
            MEMWB_o_memToReg => i_memToReg
        );

    writeback: WB_stage
        port map(
            -- inputs
            clk => clk,
            resetBar => resetBar,
            load => '1',
            i_regWrite => i_regWrite,
            i_memToReg => i_memToReg,
            i_memData => i_memData,
            i_aluResult => i_aluResult,
            i_EXMEM_rd => i_EXMEM_rd,
            -- outputs
            o_writeData => WB_writeData,
            o_MEMWB_rd => WB_writeReg,
            o_MEMWB_regWrite => WB_regWrite
        );  

    forward: forwarding_unit
        port map(
            -- input
            ID_rs => IDEX_i_rs,
            ID_rt => IDEX_i_rt,
            IDEX_rs => IDEX_rs,
            IDEX_rt => IDEX_rt,
            EXMEM_rd => i_EXMEM_rd,
            MEMWB_rd => WB_writeReg,
            EXMEM_RegWrite => i_regWrite,
            MEMWB_RegWrite => WB_regWrite,
            -- output
            ForwardA => ForwardA_sel,
            ForwardB => ForwardB_sel,
            ForwardC => ID_forwardC,
            ForwardD => ID_forwardD
        );
    
    hazard: hazard_detection
        port map(
            -- input
            if_id_branch => ID_branch,
            if_id_rs => IFID_instr(25 downto 21),
            if_id_rt => IFID_instr(20 downto 16),
            id_ex_mem_read => IDEX_i_memRead,
            id_ex_branch_taken => IDEX_branch_taken,
            id_ex_rt => IDEX_rt,
            id_ex_rd => IDEX_rd,
            ex_mem_read => ex_mem_read,
            ex_mem_rt => i_EXMEM_rd,
            -- outputs
            pc_write => IF_pc_write,
            if_id_en => IFID_en,
            if_id_flush => IFID_flush,
            id_ex_flush => IDEX_flush
        );

end structural;