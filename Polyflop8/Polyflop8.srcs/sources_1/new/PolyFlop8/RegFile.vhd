-- ============================================================================
-- File:         RegFile.vhd
-- Description:  Register File for PolyFlop8 Processor
--                This file has been verified with the following test cases:
--                - Reset Verification (TC-REG-01)
--                - LDI - Write Immediate to R1 (TC-REG-02)
--                - ALU Write Back to R2 (TC-REG-03)
--                - RAM Load to R3 (TC-REG-04)
--                - Register Isolation Check (TC-REG-05)
--                - Write Enable Protection (TC-REG-06)
--                - R7 Hardwired Output Verification (TC-REG-07)
--                - 100% code coverage of Register File behavioral description
--
-- Author:       Artem Horiunov
-- Date:         05.01.2026
-- Version:      1.0
-- Status:       VERIFIED
-- Test Report:  TC-REG-001
-- ============================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegFile is
    Port (
        clk       : in  STD_LOGIC;                      -- Zegar systemowy
        reset     : in  STD_LOGIC;                      -- Reset asynchroniczny
        we        : in  STD_LOGIC;                      -- Write Enable (ze sterownika)
        
        -- ADRESY (3-bitowe dla 8 rejestrów)
        addr_a    : in  STD_LOGIC_VECTOR (2 downto 0); -- Adres odczytu A (Rs)
        addr_b    : in  STD_LOGIC_VECTOR (2 downto 0); -- Adres odczytu B (Rd - jako źródło)
        addr_w    : in  STD_LOGIC_VECTOR (2 downto 0); -- Adres zapisu (Rd - jako cel)
        
        -- SYGNAŁ STERUJĄCY MUXEM (z Control Unit)
        rf_src_sel: in  STD_LOGIC_VECTOR (2 downto 0); -- Wybór źródła danych do zapisu
        
        -- DANE WEJŚCIOWE DO MUXA (Write Back Data Sources)
        alu_out    : in  STD_LOGIC_VECTOR (7 downto 0); -- Wynik z ALU (np. ADD, SUB)
        ram_data   : in  STD_LOGIC_VECTOR (7 downto 0); -- Dane z RAM (instrukcja LD/POP)
        rs_imm_in  : in  STD_LOGIC_VECTOR (7 downto 0); -- Wartość natychmiastowa (instrukcja LDI/MOV)
        io_data_in : in  STD_LOGIC_VECTOR (7 downto 0); -- Dane z portów IO (instrukcja IN)
        sreg_data  : in  STD_LOGIC_VECTOR (7 downto 0); -- Dane z rejestru flag (rzadkie, ale możliwe)
        
        -- WYJŚCIA
        data_a    : out STD_LOGIC_VECTOR (7 downto 0); -- Wyjście portu A (do ALU)
        data_b    : out STD_LOGIC_VECTOR (7 downto 0); -- Wyjście portu B (do ALU / RAM data_w)
        data_r7x  : out STD_LOGIC_VECTOR (7 downto 0)  -- Sztywne wyjście R7 (X-Pointer do RAM)
    );
end RegFile;

architecture Behavioral of RegFile is
    -- Definicja tablicy rejestrów: 8 rejestrów po 8 bitów
    type reg_array_type is array (0 to 7) of std_logic_vector(7 downto 0);
    
    -- Inicjalizacja zerami
    signal registers : reg_array_type := (others => (others => '0'));

    -- Sygnał wewnętrzny po multiplekserze (to, co faktycznie trafi do rejestru)
    signal write_data_mux : std_logic_vector(7 downto 0);

begin

    -- =========================================================
    -- 1. MULTIPLEKSER WEJŚCIOWY (WRITE-BACK MUX)
    -- =========================================================
    -- Decyduje, co zapisujemy do rejestru. Sterowany przez rf_src_sel.
    with rf_src_sel select
        write_data_mux <= 
            alu_out     when "000",  -- Większość operacji arytmetycznych
            ram_data    when "001",  -- Odczyt z pamięci (LD, POP)
            rs_imm_in   when "010",  -- Ładowanie stałej (LDI, MOVI)
            io_data_in  when "011",  -- Odczyt z wejść (IN)
            sreg_data   when "100",  -- Zapis flag do rejestru (opcjonalne)
            (others=>'0') when others; -- Zabezpieczenie

    -- =========================================================
    -- 2. PROCES ZAPISU (SYNCHRONICZNY)
    -- =========================================================
    process(clk, reset)
    begin
        if reset = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if we = '1' then
                -- Zapisujemy wyselekcjonowaną wartość pod wskazany adres
                registers(to_integer(unsigned(addr_w))) <= write_data_mux;
            end if;
        end if;
    end process;

    -- =========================================================
    -- 3. ODCZYT ASYNCHRONICZNY (KOMBINACYJNY)
    -- =========================================================
    -- Dane są dostępne natychmiast po zmianie adresu (dla ALU).
    data_a <= registers(to_integer(unsigned(addr_a)));
    data_b <= registers(to_integer(unsigned(addr_b)));

    -- =========================================================
    -- 4. SPECJALNE WYJŚCIE R7 (X-POINTER)
    -- =========================================================
    -- Bezpośrednie podłączenie rejestru R7 do kontrolera pamięci RAM
    -- Umożliwia adresowanie pośrednie (np. LD R1, [R7]) bez użycia ALU.
    data_r7x <= registers(7);

end Behavioral;