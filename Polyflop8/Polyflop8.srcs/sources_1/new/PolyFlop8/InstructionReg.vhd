library ieee;
use ieee.std_logic_1164.all;

entity instruction_register is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        ir_en    : in  std_logic;                     -- Enable signal from Control Unit
        data_in  : in  std_logic_vector(15 downto 0); -- From Program Memory (ROM)
        ir_out   : out std_logic_vector(15 downto 0); -- Full instruction to Decoder
        opcode   : out std_logic_vector(7 downto 0);  -- Split: High byte (Operation)
        argument : out std_logic_vector(7 downto 0)   -- Split: Low byte (Data/Address)
    );
end entity;

architecture behavioral of instruction_register is
    signal ir_reg : std_logic_vector(15 downto 0) := (others => '0');
begin

    -- Synchronous process for the IR register
    process(clk, reset)
    begin
        if reset = '1' then
            ir_reg <= (others => '0'); -- Reset to NOP (usually 0x0000)
        elsif rising_edge(clk) then
            if ir_en = '1' then
                ir_reg <= data_in;     -- Latch the instruction from ROM
            end if;
        end if;
    end process;

    -- Output logic
    ir_out   <= ir_reg;
    opcode   <= ir_reg(15 downto 8); -- As defined in Lab 7/8 instruction sets
    argument <= ir_reg(7 downto 0);

end architecture;