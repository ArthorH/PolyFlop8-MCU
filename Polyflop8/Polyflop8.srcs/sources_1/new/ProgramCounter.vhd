library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgramCounter is
    Port (
        clk     : in  STD_LOGIC;                      -- Zegar
        rst     : in  STD_LOGIC;                      -- Reset
        pc_en   : in  STD_LOGIC;                      -- Zezwolenie na zmianę PC (Write Enable)
        
        -- MUX SELECTOR (z Control Unit)
        -- "00" = PC + 1 (Next Instruction)
        -- "01" = PC + 1 + Offset (Branch - skok względny)
        -- "10" = RAM Data (Return / Indirect Jump)
        -- "11" = Absolute Jump 11-bit (JMP / CALL)
        pc_src  : in  STD_LOGIC_VECTOR (1 downto 0); 
        
        -- DANE WEJŚCIOWE DO MUXA
        alu_out      : in  STD_LOGIC_VECTOR (7 downto 0);  -- Offset (signed) dla Branch
        ram_data     : in  STD_LOGIC_VECTOR (7 downto 0);  -- Adres powrotu (np. ze stosu)
        jump_abs_11bit : in STD_LOGIC_VECTOR (10 downto 0); -- Długi skok z dekodera
        
        -- WYJŚCIE ADRESOWE
        -- Zmienione na 11 bitów, aby obsłużyć pełną przestrzeń adresową
        pc_out  : out STD_LOGIC_VECTOR (10 downto 0)  
    );
end ProgramCounter;

architecture Behavioral of ProgramCounter is
    -- Rejestr licznika (11 bitów)
    signal pc_reg : unsigned(10 downto 0) := (others => '0');
    
    -- Sygnał pomocniczy "PC + 1" (widoczny na Twoim schemacie jako blok "+1")
    signal pc_next_sequential : unsigned(10 downto 0);

begin

    -- =========================================================
    -- 1. LOGIKA INKREMENTATORA (+1)
    -- =========================================================
    -- Ten blok działa ciągle, niezależnie od zegara (kombinacyjnie).
    -- Oblicza adres następnej instrukcji.
    pc_next_sequential <= pc_reg + 1;

    -- =========================================================
    -- 2. REJESTR Z WEWNĘTRZNYM MULTIPLEKSEREM
    -- =========================================================
    process(clk, rst)
        -- Zmienna do obliczenia adresu skoku względnego
        variable v_offset_extended : signed(10 downto 0);
    begin
        if rst = '1' then
            pc_reg <= (others => '0'); -- Reset do adresu 0x000
            
        elsif rising_edge(clk) then
            if pc_en = '1' then
                case pc_src is
                    
                    -- CASE "00": Inkrementacja (FETCH)
                    when "00" => 
                        pc_reg <= pc_next_sequential;
                    
                    -- CASE "01": Branch (Skok względny warunkowy)
                    -- Logika: PC_new = (PC_old + 1) + Offset
                    when "01" => 
                        -- Rozszerzamy 8-bitowy offset (alu_out) ze znakiem do 11 bitów
                        v_offset_extended := resize(signed(alu_out), 11);
                        -- Dodajemy offset do następnej instrukcji
                        pc_reg <= unsigned(signed(pc_next_sequential) + v_offset_extended);
                        
                    -- CASE "10": Dane z pamięci (RET / Indirect)
                    when "10" =>
                        -- Ponieważ ram_data ma 8 bitów, musimy dopasować je do 11 bitów.
                        -- Zakładamy, że górne bity są zerami (strona 0 pamięci) lub
                        -- system wymagałby 2 cykli na wczytanie 16 bitów (tu wersja prosta).
                        pc_reg <= resize(unsigned(ram_data), 11);
                        
                    -- CASE "11": Absolute Jump (JMP / CALL)
                    when "11" =>
                        -- Ładujemy czysty adres 11-bitowy z instrukcji
                        pc_reg <= unsigned(jump_abs_11bit);
                        
                    when others =>
                        pc_reg <= pc_next_sequential; -- Domyślne zachowanie
                end case;
            end if;
            -- Jeśli pc_en = '0', pc_reg pamięta starą wartość (Stall)
        end if;
    end process;

    -- Przypisanie rejestru na wyjście
    pc_out <= std_logic_vector(pc_reg);

end Behavioral;