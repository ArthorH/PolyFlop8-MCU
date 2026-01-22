library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_PolyFlop8_MCU is
    -- Testbench nie ma portów zewn?trznych
end tb_PolyFlop8_MCU;

architecture Behavioral of tb_PolyFlop8_MCU is

    -- Deklaracja komponentu (Unit Under Test - UUT)
    component PolyFlop8_MCU
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            port_out_a : out STD_LOGIC_VECTOR (7 downto 0);
            pin_in_b   : in  STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- Sygna?y do pod??czenia
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal port_out_a : std_logic_vector(7 downto 0);
    signal pin_in_b   : std_logic_vector(7 downto 0) := (others => '0');

    -- Sta?a zegara (100 MHz)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancjacja Twojego procesora
    uut: PolyFlop8_MCU port map (
        clk        => clk,
        reset      => reset,
        port_out_a => port_out_a,
        pin_in_b   => pin_in_b
    );

    -- Proces generuj?cy zegar
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Proces stymuluj?cy (g?ówny test)
    stim_proc: process
    begin
        -- 1. Stan pocz?tkowy i Reset
        report ">>> START SYMULACJI <<<";
        pin_in_b <= x"00"; -- Ustawiamy zera na wej?ciu, ?eby nie by?o 'U'
        reset <= '1';      -- Aktywny reset
        wait for 100 ns;   -- Trzymamy reset przez chwil?
        
        -- 2. Zwolnienie resetu - procesor startuje
        reset <= '0';
        report ">>> RESET ZWOLNIONY - PROCESOR RUSZA <<<";

        -- 3. Oczekiwanie na wykonanie programu
        -- Program ma ok. 13 instrukcji. Przyjmijmy margines czasu.
        -- 200 cykli zegara powinno wystarczy? z zapasem.
        wait for 200 * CLK_PERIOD;

        -- 4. Weryfikacja wyniku
        -- Program w ROM liczy 3 * 9 = 27 (dec) -> 0x1B (hex)
        
        if unsigned(port_out_a) = 27 then
            report ">>> SUKCES: Wynik poprawny! Otrzymano 27 na porcie A." severity note;
        else
            report ">>> PORAZKA: Oczekiwano 27, otrzymano " & integer'image(to_integer(unsigned(port_out_a))) severity error;
        end if;

        -- 5. Koniec testu
        report ">>> KONIEC SYMULACJI <<<";
        wait; -- Zatrzymanie procesu
    end process;

end Behavioral;