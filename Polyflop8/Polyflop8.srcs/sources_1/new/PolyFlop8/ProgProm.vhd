library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgPROM is
    Port (
        clk      : in  STD_LOGIC;
        address  : in  STD_LOGIC_VECTOR (10 downto 0);
        data_out : out STD_LOGIC_VECTOR (15 downto 0);
        enable   : in  STD_LOGIC
    );
end ProgPROM;

architecture Behavioral of ProgPROM is

    -- =========================================================================
    -- 1. TWOJE KODY (Te, które potwierdzi?e?)
    -- =========================================================================
    constant OP_ADD  : std_logic_vector(4 downto 0) := "00000";
    constant OP_LDI  : std_logic_vector(4 downto 0) := "01001";
    constant OP_OUT  : std_logic_vector(4 downto 0) := "11101";
    constant OP_RJMP : std_logic_vector(4 downto 0) := "01111";

    type rom_type is array (0 to 2047) of std_logic_vector(15 downto 0);

    -- =========================================================================
    -- 2. PROGRAM: 3^3 = 27 (Bez p?tli, metoda liniowa)
    -- =========================================================================
    -- Algorytm: R2 = 0 + 3 + 3 + 3 + 3 + 3 + 3 + 3 + 3 + 3 (Razem 9 razy)
    
    constant ROM : rom_type := (
        -- 0: LDI R0, 3 (Sta?a do dodawania)
        0 => OP_LDI & "000" & "00000011", 
        
        -- 1: LDI R2, 0 (Wyczy?? wynik)
        1 => OP_LDI & "010" & "00000000", 

        -- Teraz 9 razy dodajemy R0 do R2:
        
        -- 2: ADD R2, R0 (Wynik = 3)
        2 => OP_ADD & "010" & "000" & "00000", 
        
        -- 3: ADD R2, R0 (Wynik = 6)
        3 => OP_ADD & "010" & "000" & "00000",
        
        -- 4: ADD R2, R0 (Wynik = 9)
        4 => OP_ADD & "010" & "000" & "00000",
        
        -- 5: ADD R2, R0 (Wynik = 12)
        5 => OP_ADD & "010" & "000" & "00000",
        
        -- 6: ADD R2, R0 (Wynik = 15)
        6 => OP_ADD & "010" & "000" & "00000",
        
        -- 7: ADD R2, R0 (Wynik = 18)
        7 => OP_ADD & "010" & "000" & "00000",
        
        -- 8: ADD R2, R0 (Wynik = 21)
        8 => OP_ADD & "010" & "000" & "00000",
        
        -- 9: ADD R2, R0 (Wynik = 24)
        9 => OP_ADD & "010" & "000" & "00000",
        
        -- 10: ADD R2, R0 (Wynik = 27) -> SUKCES!
        10 => OP_ADD & "010" & "000" & "00000",

        -- 11: OUT R2 (Wystaw 27 na LEDy)
        11 => OP_OUT & "010" & "00000000", 
        
        -- 12: RJMP -1 (Stop - niesko?czona p?tla w miejscu)
        12 => OP_RJMP & "000" & "11111111",

        others => (others => '0')
    );

begin
    process(clk)
    begin
        if rising_edge(clk) then
             if enable = '1' then
                data_out <= ROM(to_integer(unsigned(address)));
             end if;
        end if;
    end process;
end Behavioral;