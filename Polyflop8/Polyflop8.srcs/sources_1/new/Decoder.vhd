library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Decoder is
    Port (
        -- Wejście: 16-bitowe słowo instrukcji
        decoder_data_in : in  STD_LOGIC_VECTOR (15 downto 0); 

        -- Wyjścia: Pocięte kawałki instrukcji

        -- 1. Opcode (5 bitów) - Bity [15:11]
        -- Zmieniłeś z 4 na 5 bitów, więc teraz masz 32 możliwe instrukcje.
        opcode : out STD_LOGIC_VECTOR (4 downto 0); 

        -- 2. Destination Register (3 bity) - Bity [10:8]
        RD : out STD_LOGIC_VECTOR (2 downto 0); 

        -- 3. RS / IMM (8 bitów) - Bity [7:0]
        -- "Worek na wszystko": RS (bity 7:5) lub Immediate (7:0)
        RS_IMM : out STD_LOGIC_VECTOR (7 downto 0);

        -- 4. Jump Address (11 bitów) - Bity [10:0]
        -- Długi adres skoku. Zauważ, że te bity fizycznie pokrywają się z RD i RS_IMM.
        Jump11bit : out STD_LOGIC_VECTOR (10 downto 0)
    );
end Decoder;

architecture Behavioral of Decoder is
begin
    -- =========================================================
    -- HARDWIRED SLICING (Sztywne cięcie przewodów)
    -- =========================================================
    -- Blok jest czysto kombinacyjny. Opóźnienie jest bliskie zeru.

    -- [15..11] -> Opcode
    opcode <= decoder_data_in(15 downto 11);

    -- [10..8] -> RD (Target Register)
    RD <= decoder_data_in(10 downto 8);

    -- [7..0] -> RS_IMM (Source / Immediate)
    -- Control Unit zdecyduje, czy MUX-y wezmą z tego 3 bity (adres RS) 
    -- czy 8 bitów (liczbę).
    RS_IMM <= decoder_data_in(7 downto 0);

    -- [10..0] -> Jump Address (11 bitów)
    -- To wyjście "zjada" bity, które normalnie byłyby RD i RS_IMM.
    -- Używane tylko gdy Opcode wskazuje na skok (np. JMP, CALL).
    Jump11bit <= decoder_data_in(10 downto 0);

end Behavioral;