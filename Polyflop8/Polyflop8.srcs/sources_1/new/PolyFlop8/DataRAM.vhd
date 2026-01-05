library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataRAM is
    Port (
        clk            : in  STD_LOGIC;                      -- Zegar systemowy
        mem_we         : in  STD_LOGIC;                      -- Memory Write Enable
        
        -- =========================================================
        -- SYGNAŁY STERUJĄCE (SELECTORS)
        -- =========================================================
        
        -- Wybór źródła ADRESU (Address Mux)
        -- "00" = Adres z ALU (obliczony offset)
        -- "01" = Adres z R7 (wskaźnik X)
        -- "10" = Adres z Reg A (adresowanie rejestrowe pośrednie [Ra])
        -- "11" = Adres natychmiastowy (adresowanie bezpośrednie [Imm])
        mem_addr_sel   : in  STD_LOGIC_VECTOR(1 downto 0);

        -- Wybór źródła DANYCH (Data Mux)
        -- "00" = Dane z Rejestru B (ST - Store)
        -- "01" = Dane z PC (CALL - zapis powrotu na stos)
        -- "10" = Dane z ALU (opcjonalne)
        mem_data_sel   : in  STD_LOGIC_VECTOR(1 downto 0);
        
        -- =========================================================
        -- DANE WEJŚCIOWE (INPUTS)
        -- =========================================================
        
        -- 1. Źródła dla DANYCH (Data Mux Inputs)
        regfile_data_b : in  STD_LOGIC_VECTOR (7 downto 0); -- Źródło: Rejestr (ST)
        alu_out        : in  STD_LOGIC_VECTOR (7 downto 0); -- Źródło: Wynik ALU
        pc_data        : in  STD_LOGIC_VECTOR (7 downto 0); -- Źródło: Licznik rozkazów (CALL)
        
        -- 2. Źródła dla ADRESU (Address Mux Inputs)
        data_reg7x     : in  STD_LOGIC_VECTOR (7 downto 0); -- Adres bazowy (z R7)
        regfile_data_a : in  STD_LOGIC_VECTOR (7 downto 0); -- Adres z dowolnego rejestru (np. [R1])
        rs_imm_data    : in  STD_LOGIC_VECTOR (7 downto 0); -- Adres natychmiastowy (stała z instrukcji)
        
        -- =========================================================
        -- WYJŚCIE
        -- =========================================================
        ram_data_out   : out STD_LOGIC_VECTOR (7 downto 0)  -- Dane odczytane z pamięci
    );
end DataRAM;

architecture Behavioral of DataRAM is

    -- Definicja pamięci: 256 bajtów
    type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
    
    -- Inicjalizacja zerami
    signal ram : ram_type := (others => (others => '0'));

    -- Sygnały wewnętrzne po multiplekserach
    signal selected_address : std_logic_vector(7 downto 0);
    signal selected_data    : std_logic_vector(7 downto 0);

begin

    -- =========================================================
    -- 1. MUX ADRESOWY (Address Mux)
    -- =========================================================
    with mem_addr_sel select
        selected_address <= 
            alu_out         when "00", 
            data_reg7x      when "01", 
            regfile_data_a  when "10", 
            rs_imm_data     when "11", 
            (others => '0') when others;

    -- =========================================================
    -- 2. MUX DANYCH (Data Mux)
    -- =========================================================
    with mem_data_sel select
        selected_data <= 
            regfile_data_b  when "00", 
            pc_data         when "01", 
            alu_out         when "10", 
            (others => '0') when others;

    -- =========================================================
    -- 3. PROCES ZAPISU (Synchroniczny)
    -- =========================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_we = '1' then
                ram(to_integer(unsigned(selected_address))) <= selected_data;
            end if;
        end if;
    end process;

    -- =========================================================
    -- 4. ODCZYT (Asynchroniczny)
    -- =========================================================
    ram_data_out <= ram(to_integer(unsigned(selected_address)));

end Behavioral;