library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgPROM is
    Port (
        -- Porty zegara i resetu (dla kompatybilności, choć ten ROM jest asynchroniczny)
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        
        -- Wejście adresowe z Program Countera
        -- UWAGA: Zmienione na 11 bitów, aby pasowało do PC i obsługiwało Jump11bit
        address  : in  STD_LOGIC_VECTOR (10 downto 0);
        
        -- Wyjście danych (Instrukcja 16-bitowa do Instruction Register)
        data_out : out STD_LOGIC_VECTOR (15 downto 0)
    );
end ProgPROM;

architecture Behavioral of ProgPROM is
    
    -- =========================================================
    -- 1. "SYMULOWANY ASEMBLER" (Definicje stałych dla czytelności)
    -- =========================================================
    -- Dzięki temu nie musimy pisać ręcznie "10000", tylko używamy nazw.
    constant OP_ADD : std_logic_vector(4 downto 0) := "00000";
    constant OP_SUB : std_logic_vector(4 downto 0) := "00010";
    constant OP_MOV : std_logic_vector(4 downto 0) := "01110"; -- MOV Rd, Rs (Pass B)
    constant OP_LDI : std_logic_vector(4 downto 0) := "10000"; -- LDI Rd, Imm
    constant OP_JMP : std_logic_vector(4 downto 0) := "11000"; -- JMP Address (11 bit)

    -- Definicja typu tablicy pamięci (2048 słów x 16 bitów = 2^11)
    type rom_type is array (0 to 2047) of std_logic_vector(15 downto 0);

    -- =========================================================
    -- 2. ZAWARTOŚĆ PAMIĘCI (Twój Program)
    -- =========================================================
    constant ROM : rom_type := (
        
        -- -----------------------------------------------------
        -- Adres 0x000: LDI R1, 10 (Ładuj 10 dec do R1)
        -- Opcode(5) & Rd(3) & Imm(8)
        -- -----------------------------------------------------
        0 => OP_LDI & "001" & "00001010", -- R1 = 10 (0x0A)

        -- -----------------------------------------------------
        -- Adres 0x001: LDI R2, 5 (Ładuj 5 dec do R2)
        -- -----------------------------------------------------
        1 => OP_LDI & "010" & "00000101", -- R2 = 5 (0x05)

        -- -----------------------------------------------------
        -- Adres 0x002: ADD R1, R2 (R1 = R1 + R2)
        -- Opcode(5) & Rd(3) & Rs(3) & Padding(5)
        -- Wartość Rs (010) trafia na bity 7..5.
        -- -----------------------------------------------------
        2 => OP_ADD & "001" & "010" & "00000", -- Wynik: R1 = 15 (0x0F)
        
        -- -----------------------------------------------------
        -- Adres 0x003: SUB R1, R2 (R1 = R1 - R2)
        -- Odejmujemy 5 od 15. Wynik 10.
        -- -----------------------------------------------------
        3 => OP_SUB & "001" & "010" & "00000", -- Wynik: R1 = 10 (0x0A)

        -- -----------------------------------------------------
        -- Adres 0x004: JMP 0x000 (Skok bezwzględny na początek)
        -- Opcode(5) & Address(11)
        -- Format J-Type: Bity adresu pokrywają się z polami Rd i Rs/Imm
        -- -----------------------------------------------------
        4 => OP_JMP & "00000000000", -- Skok do adresu 0

        -- Reszta pamięci to NOP-y (same zera -> ADD R0, R0)
        others => (others => '0')
    );

begin

    -- =========================================================
    -- 3. ODCZYT ASYNCHRONICZNY (Combinational Read)
    -- =========================================================
    process(address)
    begin
        -- Konwersja wektora STD_LOGIC na Integer do indeksowania tablicy
        -- Jeśli adres wyjdzie poza zakres (teoretycznie niemożliwe przy dopasowanych bitach),
        -- VHDL w symulacji zgłosi błąd, ale w syntezie to po prostu RAM/LUT.
        data_out <= ROM(to_integer(unsigned(address)));
    end process;

end Behavioral;