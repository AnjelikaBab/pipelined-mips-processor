library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection is
    port (
        if_id_branch: in std_logic;
        id_ex_mem_read, id_ex_branch_taken: in std_logic;
        ex_mem_read: in std_logic;
        if_id_rs, if_id_rt: in std_logic_vector(4 downto 0);
        id_ex_rt, id_ex_rd: in std_logic_vector(4 downto 0);
        ex_mem_rt: in std_logic_vector(4 downto 0);
        pc_write, if_id_en: out std_logic;
        if_id_flush, id_ex_flush: out std_logic
    );
end hazard_detection;

architecture structural of hazard_detection is
    SIGNAL condition1, condition2, condition3, condition4: std_logic;

begin
    condition1 <= (id_ex_mem_read and ((id_ex_rt = if_id_rs) or (id_ex_rt = if_id_rt))); -- memory hazard
    condition2 <= (id_ex_branch_taken); -- flush condition
    -- dependency between branch and instruction in EX
    condition3 <= (if_id_branch and ((id_ex_rd = if_id_rs) or (id_ex_rd = if_id_rt)));  
    -- dependency between branch and LW instruction
    condition4 <= (if_id_branch and ex_mem_read and ((ex_mem_rt = if_id_rs) or (ex_mem_rt = if_id_rt))); 

    -- drive outputs
    pc_write <= not (condition1 or condition3 or condition4);
    if_id_en <= not (condition1 or condition3 or condition4);
    id_ex_flush <= condition1 or condition3 or condition4;
    if_id_flush <= condition2;

end structural;
