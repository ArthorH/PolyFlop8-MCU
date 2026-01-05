-- ============================================================================
-- File:         InstructionReg.vhd
-- Description:  Instruction Register for PolyFlop8 Processor
--                This file has been verified with the following test cases:
--                - Asynchronous reset functionality (TC-IR-001-01, TC-IR-001-04)
--                - Data write functionality (TC-IR-001-02)
--                - Data hold functionality (TC-IR-001-03)
--                - Stability during asynchronous reset (TC-IR-001-04)
--                - 100% code coverage of Instruction Register behavioral description
--
-- Author:       Artem Horiunov
-- Date:         05.01.2026
-- Version:      1.0
-- Status:       VERIFIED
-- Test Report:  PolyFlop8-MCU\Documentation\Testability\TestReports-UnitTest\TC-IR-001
-- ============================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionReg is
    Port (
        clk       : in  STD_LOGIC;                      -- Zegar systemowy
        rst       : in  STD_LOGIC;                      -- Reset asynchroniczny
        ir_en     : in  STD_LOGIC;                      -- Włącznik zapisu (Active High)
        
        -- Wejście danych (zazwyczaj z wyjścia Pamięci/ROM)
        data_in   : in  STD_LOGIC_VECTOR (15 downto 0); 
        
        -- Wyjście do Dekodera i Control Unit
        ir_data_out : out STD_LOGIC_VECTOR (15 downto 0)  
    );
end InstructionReg;

architecture Behavioral of InstructionReg is
    -- Rejestr wewnętrzny przechowujący obecną instrukcję
    signal instruction_reg : std_logic_vector(15 downto 0) := (others => '0');

begin

    process(clk, rst)
    begin
        -- 1. Reset asynchroniczny
        if rst = '1' then
            instruction_reg <= (others => '0'); -- Reset do NOP (same zera)
            
        -- 2. Zapis synchroniczny
        elsif rising_edge(clk) then
            -- Rejestr łapie nową instrukcję TYLKO gdy Control Unit pozwoli (stan FETCH)
            if ir_en = '1' then
                instruction_reg <= data_in; -- Pobranie danej z wejścia
            end if;
            -- Jeśli ir_en = '0', instrukcja pozostaje zatrzaśnięta (stabilna dla DECODE/EXECUTE)
        end if;
    end process;

    -- Wystawienie sygnału na zewnątrz
    ir_data_out <= instruction_reg;

end Behavioral;