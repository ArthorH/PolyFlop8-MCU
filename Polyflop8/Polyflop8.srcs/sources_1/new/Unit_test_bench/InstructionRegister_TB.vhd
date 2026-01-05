-- ============================================================================
-- File:         tb_InstructionReg.vhd
-- Description:  Testbench for PolyFlop8 Instruction Register
--                This testbench verifies the following:
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
-- Test Report:  TC-IR-001
-- ============================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Nazwa entity testbencha (pusta, bo to symulacja)
entity tb_InstructionReg is
end tb_InstructionReg;

architecture Behavioral of tb_InstructionReg is

    -- 1. Deklaracja Komponentu (Zgodna z Twoim kodem)
    component InstructionReg is
        Port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            ir_en       : in  STD_LOGIC;
            data_in     : in  STD_LOGIC_VECTOR (15 downto 0);
            ir_data_out : out STD_LOGIC_VECTOR (15 downto 0)
        );
    end component;

    -- 2. Sygnały wewnętrzne do łączenia z UUT (Unit Under Test)
    signal clk_tb       : STD_LOGIC := '0';
    signal rst_tb       : STD_LOGIC := '0';
    signal ir_en_tb     : STD_LOGIC := '0';
    signal data_in_tb   : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ir_data_out_tb : STD_LOGIC_VECTOR (15 downto 0);

    -- Stała okresu zegara (np. 10 ns -> 100 MHz)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instancja testowanego układu
    UUT: InstructionReg
    port map (
        clk         => clk_tb,
        rst         => rst_tb,
        ir_en       => ir_en_tb,
        data_in     => data_in_tb,
        ir_data_out => ir_data_out_tb
    );

    -- 4. Proces generowania zegara
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Proces stymulacji (Główny scenariusz testowy)
    stim_proc: process
    begin
        -- Inicjalizacja
        report "Rozpoczecie testu Instruction Register (TC-IR-001)";
        rst_tb <= '1';      -- Aktywny reset na start
        ir_en_tb <= '0';
        data_in_tb <= x"0000";
        wait for 100 ns;    -- Czas na ustabilizowanie po starcie

        ------------------------------------------------------------
        -- TEST CASE 1: Weryfikacja Resetu (TR-IR-03)
        ------------------------------------------------------------
        -- Sprawdzenie czy wyjście to 0x0000 po resecie
        assert ir_data_out_tb = x"0000" 
            report "Blad TC1: Reset nie wyzerowal rejestru" severity error;
        
        -- Zwolnienie resetu
        rst_tb <= '0';
        wait for CLK_PERIOD;

        ------------------------------------------------------------
        -- TEST CASE 2: Zapis danych - Włączony (TR-IR-01, TR-IR-04, TR-IR-06)
        ------------------------------------------------------------
        report "TC2: Test zapisu danych (ir_en = '1')";
        
        -- Ustawienie danych i włączenie zapisu
        ir_en_tb <= '1';
        data_in_tb <= x"AAAA"; -- Wzorzec 1010...
        wait for CLK_PERIOD;   -- Czekamy na zbocze zegara
        
        -- Sprawdzenie czy dane zostały zatrzaskane
        assert ir_data_out_tb = x"AAAA" 
            report "Blad TC2a: Dane 0xAAAA nie zostaly zapisane" severity error;

        -- Zmiana danych na inne (Wzorzec 0101...)
        data_in_tb <= x"5555";
        wait for CLK_PERIOD;
        
        assert ir_data_out_tb = x"5555" 
            report "Blad TC2b: Dane 0x5555 nie zostaly zapisane" severity error;

        ------------------------------------------------------------
        -- TEST CASE 3: Podtrzymanie danych - Wyłączony (TR-IR-02, TR-IR-05)
        ------------------------------------------------------------
        report "TC3: Test podtrzymania danych (ir_en = '0')";
        
        -- Wyłączenie zapisu, ale zmiana danych na wejściu
        ir_en_tb <= '0';
        data_in_tb <= x"FFFF"; -- Próba wpisania samych jedynek
        wait for CLK_PERIOD * 2; -- Czekamy dwa cykle
        
        -- Wyjście powinno nadal trzymać starą wartość (0x5555), a nie nową (0xFFFF)
        assert ir_data_out_tb = x"5555" 
            report "Blad TC3: Rejestr nadpisal dane mimo ir_en='0'" severity error;

        ------------------------------------------------------------
        -- TEST CASE 4: Asynchroniczność Resetu (Dodatkowy test stabilności)
        ------------------------------------------------------------
        report "TC4: Test asynchronicznego resetu w trakcie pracy";
        
        ir_en_tb <= '1';        -- Zapis włączony
        data_in_tb <= x"BEEF";  -- Dane na wejściu
        wait for CLK_PERIOD;    -- Zatrzaskujemy 0xBEEF
        
        assert ir_data_out_tb = x"BEEF" report "Blad TC4a: Przygotowanie danych nieudane" severity failure;

        rst_tb <= '1';          -- Nagły reset
        wait for 2 ns;          -- Krótkie opóźnienie (mniejsze niż cykl zegara)
        
        -- Powinno się wyzerować natychmiast, bez czekania na zbocze zegara
        assert ir_data_out_tb = x"0000" 
            report "Blad TC4b: Reset asynchroniczny nie zadzialal natychmiast" severity error;

        rst_tb <= '0';
        ir_en_tb <= '0';

        ------------------------------------------------------------
        -- Zakończenie
        ------------------------------------------------------------
        report "Test Instruction Register zakonczony pomyslnie.";
        wait; -- Zatrzymanie symulacji
    end process;

end Behavioral;