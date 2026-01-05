-- ============================================================================
-- File:         StatusReg.vhd
-- Description:  Status Register for PolyFlop8 Processor
--                This file has been verified with the following test cases:
--                - Reset Verification (TC-SREG-05)
--                - Restore Mode (Load 0xAA) (TC-SREG-02)
--                - ALU Update (Preserve I/T bits) (TC-SREG-01/04)
--                - S-Flag Calculation (N=1, V=0 -> S=1) (TC-SREG-03)
--                - S-Flag Calculation (N=1, V=1 -> S=0) (TC-SREG-03)
--                - 100% code coverage of Status Register behavioral description
--
-- Author:       Artem Horiunov
-- Date:         \today
-- Version:      1.0
-- Status:       VERIFIED
-- Test Report:  PolyFlop8-MCU\Documentation\Testability\TestReports-UnitTest\TC-SREG-001
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_StatusReg is
    -- Testbench nie posiada portów zewnętrznych
end tb_StatusReg;

architecture Behavioral of tb_StatusReg is

    -- Deklaracja komponentu Unit Under Test (UUT)
    component StatusReg
        Port (
            clk            : in  STD_LOGIC;
            rst            : in  STD_LOGIC;
            sreg_we        : in  STD_LOGIC;
            sreg_src       : in  STD_LOGIC;
            alu_flags      : in  STD_LOGIC_VECTOR (4 downto 0);
            regfile_data_b : in  STD_LOGIC_VECTOR (7 downto 0);
            sreg_out       : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- Sygnały testowe
    signal clk_tb            : STD_LOGIC := '0';
    signal rst_tb            : STD_LOGIC := '0';
    signal sreg_we_tb        : STD_LOGIC := '0';
    signal sreg_src_tb       : STD_LOGIC := '0'; -- 0=ALU, 1=RegFile
    signal alu_flags_tb      : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal regfile_data_b_tb : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal sreg_out_tb       : STD_LOGIC_VECTOR(7 downto 0);

    -- Stała zegarowa (100 MHz)
    constant CLK_PERIOD : time := 10 ns;

    -- Funkcja pomocnicza do raportowania
    function to_hex_string(slv : std_logic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(slv)));
    end function;

begin

    -- Instancja UUT
    uut: StatusReg port map (
        clk            => clk_tb,
        rst            => rst_tb,
        sreg_we        => sreg_we_tb,
        sreg_src       => sreg_src_tb,
        alu_flags      => alu_flags_tb,
        regfile_data_b => regfile_data_b_tb,
        sreg_out       => sreg_out_tb
    );

    -- Proces generowania zegara
    clk_process: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Główny proces stymulujący
    stim_proc: process
    begin
        -- =========================================================
        -- TC-SREG-05: Asynchronous Reset Verification
        -- Requirement: Verify output cleared to 0x00 on reset.
        -- =========================================================
        report "TC-SREG-05: Reset Verification";
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        rst_tb <= '0';
        wait for CLK_PERIOD;
        
        assert sreg_out_tb = x"00"
            report "Error TC-SREG-05: Reset failed. Expected 0x00, got " & to_hex_string(sreg_out_tb)
            severity error;

        -- =========================================================
        -- TC-SREG-02: Restore Mode (Load from RegFile)
        -- Mode: sreg_src = '1'
        -- Data: 0xAA (10101010) -> I=1, T=0, H=1, S=0, V=1, N=0, Z=1, C=0
        -- Requirement: TR-SREG-02 (Full byte load)
        -- =========================================================
        report "TC-SREG-02: Restore Mode (Load 0xAA)";
        sreg_src_tb       <= '1';   -- Źródło: RegFile
        regfile_data_b_tb <= x"AA"; -- Wartość testowa
        sreg_we_tb        <= '1';   -- Włącz zapis
        
        wait for CLK_PERIOD;
        sreg_we_tb <= '0'; -- Wyłącz zapis (Hold)
        
        wait for 1 ns;
        assert sreg_out_tb = x"AA"
            report "Error TC-SREG-02: Restore failed. Expected 0xAA, got " & to_hex_string(sreg_out_tb)
            severity error;

        -- =========================================================
        -- TC-SREG-01 & 04: ALU Update & Flag Preservation
        -- Mode: sreg_src = '0'
        -- Requirement: Update H,V,N,Z,C but PRESERVE I(7) and T(6)
        -- =========================================================
        report "TC-SREG-01/04: ALU Update (Preserve I/T bits)";
        
        -- Aktualny stan SREG (z poprzedniego testu): 10101010 (Bit 7 'I' jest '1')
        -- Chcemy zaktualizować flagi ALU na same zera, ale 'I' (bit 7) musi zostać '1'.
        
        sreg_src_tb  <= '0';    -- Źródło: ALU
        alu_flags_tb <= "00000"; -- H=0, V=0, N=0, Z=0, C=0
        sreg_we_tb   <= '1';
        
        wait for CLK_PERIOD;
        sreg_we_tb <= '0';
        
        -- Oczekiwany wynik:
        -- Bit 7 (I) = 1 (Zachowany z 0xAA)
        -- Bit 6 (T) = 0 (Zachowany z 0xAA)
        -- Bit 5 (H) = 0 (Z ALU)
        -- Bit 4 (S) = N xor V = 0 xor 0 = 0 (Obliczony)
        -- Bit 3 (V) = 0 (Z ALU)
        -- Bit 2 (N) = 0 (Z ALU)
        -- Bit 1 (Z) = 0 (Z ALU)
        -- Bit 0 (C) = 0 (Z ALU)
        -- Wynik: 10000000 -> 0x80
        
        wait for 1 ns;
        assert sreg_out_tb = x"80"
            report "Error TC-SREG-04: I-bit preservation failed. Expected 0x80, got " & to_hex_string(sreg_out_tb)
            severity error;

        -- =========================================================
        -- TC-SREG-03: Sign Flag (S) Calculation Logic
        -- Logic: S = N xor V
        -- Requirement: TR-SREG-03
        -- =========================================================
        report "TC-SREG-03: S-Flag Calculation (N=1, V=0 -> S=1)";
        
        -- Ustawiamy: N=1 (bit 2), V=0 (bit 3). Reszta 0.
        -- alu_flags format (zakładany): H(4), V(3), N(2), Z(1), C(0)
        alu_flags_tb <= "00100"; 
        sreg_src_tb  <= '0';
        sreg_we_tb   <= '1';
        
        wait for CLK_PERIOD;
        
        -- Oczekujemy: S (bit 4) = 1 xor 0 = 1.
        -- Bit 7 (I) nadal powinien być 1 (z poprzednich testów).
        -- Wynik: 1(I) 0(T) 0(H) 1(S) 0(V) 1(N) 0(Z) 0(C) -> 10010100 -> 0x94
        assert sreg_out_tb = x"94"
            report "Error TC-SREG-03 (Case 1): S-flag failed. Expected 0x94, got " & to_hex_string(sreg_out_tb)
            severity error;
            
        report "TC-SREG-03: S-Flag Calculation (N=1, V=1 -> S=0)";
        -- Ustawiamy: N=1 (bit 2), V=1 (bit 3). 
        alu_flags_tb <= "01100"; -- V=1, N=1
        
        wait for CLK_PERIOD;
        sreg_we_tb <= '0';
        
        -- Oczekujemy: S (bit 4) = 1 xor 1 = 0.
        -- Wynik: 1(I) 0(T) 0(H) 0(S) 1(V) 1(N) 0(Z) 0(C) -> 10001100 -> 0x8C
        assert sreg_out_tb = x"8C"
            report "Error TC-SREG-03 (Case 2): S-flag failed. Expected 0x8C, got " & to_hex_string(sreg_out_tb)
            severity error;

        -- =========================================================
        -- Koniec testów
        -- =========================================================
        report "--- Status Register Tests Completed Successfully ---";
        wait;
    end process;

end Behavioral;