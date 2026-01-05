library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity StatusReg is
    Port (
        clk            : in  STD_LOGIC;                      -- Zegar systemowy
        rst            : in  STD_LOGIC;                      -- Reset asynchroniczny
        sreg_we        : in  STD_LOGIC;                      -- Write Enable (ze sterownika)
        
        -- SYGNAŁ STERUJĄCY MUXEM (NOWOŚĆ)
        -- 0 = Aktualizacja z ALU (Flagi matematyczne)
        -- 1 = Ładowanie całego bajtu z RegFile (np. POP SREG)
        sreg_src       : in  STD_LOGIC; 
        
        -- DANE WEJŚCIOWE
        -- Flagi z ALU: H, V, N, C, Z (kolejność musi pasować do ALU)
        alu_flags      : in  STD_LOGIC_VECTOR (4 downto 0); 
        
        -- Dane z rejestrów uniwersalnych (musi być 8 bitów, bo SREG ma 8 bitów)
        regfile_data_b : in  STD_LOGIC_VECTOR (7 downto 0); 
        
        -- WYJŚCIE
        sreg_out       : out STD_LOGIC_VECTOR (7 downto 0) 
    );
end StatusReg;

architecture Behavioral of StatusReg is

    -- Rejestr wewnętrzny
    -- Układ bitów (Standard AVR):
    -- Bit 7: I (Global Interrupt Enable)
    -- Bit 6: T (Bit Copy Storage)
    -- Bit 5: H (Half Carry)
    -- Bit 4: S (Sign Bit = N xor V)
    -- Bit 3: V (Two's Complement Overflow)
    -- Bit 2: N (Negative)
    -- Bit 1: Z (Zero)
    -- Bit 0: C (Carry)
    signal sreg : std_logic_vector(7 downto 0);

begin
    process(clk, rst)
    begin
        if rst = '1' then
            sreg <= (others => '0');
            
        elsif rising_edge(clk) then
            if sreg_we = '1' then
                
                -- =================================================
                -- WEWNĘTRZNY MUX SREG
                -- =================================================
                if sreg_src = '1' then
                    -- TRYB 1: Ładowanie bezpośrednie z RegFile
                    -- Używane przy: OUT SREG, Rxx lub POP SREG
                    -- Przepisujemy wszystkie 8 bitów "jak leci"
                    sreg <= regfile_data_b;
                    
                else
                    -- TRYB 0: Aktualizacja z ALU (Operacje matematyczne)
                    -- Mapowanie flag z wyjścia ALU (zgodnie z poprzednim kodem ALU: H, V, N, C, Z)
                    -- alu_flags(4) = H
                    -- alu_flags(3) = V
                    -- alu_flags(2) = N
                    -- alu_flags(1) = C
                    -- alu_flags(0) = Z
                    
                    -- Bit 0: Carry
                    sreg(0) <= alu_flags(1); 
                    
                    -- Bit 1: Zero
                    sreg(1) <= alu_flags(0); 
                    
                    -- Bit 2: Negative
                    sreg(2) <= alu_flags(2); 
                    
                    -- Bit 3: Overflow
                    sreg(3) <= alu_flags(3); 
                    
                    -- Bit 4: Sign (S = N XOR V)
                    -- Obliczane dynamicznie, bo ALU tego nie zwraca wprost
                    sreg(4) <= alu_flags(2) xor alu_flags(3); 
                    
                    -- Bit 5: Half Carry
                    sreg(5) <= alu_flags(4);
                    
                    -- Bit 6 (T) i 7 (I) nie są ruszane przez ALU
                    -- Zachowują swój poprzedni stan (Latch)
                    sreg(6) <= sreg(6); 
                    sreg(7) <= sreg(7); 
                end if;
            end if;
        end if;
    end process;

    -- Przypisanie wyjścia
    sreg_out <= sreg;

end Behavioral;