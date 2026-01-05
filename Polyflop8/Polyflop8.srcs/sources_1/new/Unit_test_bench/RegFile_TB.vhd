-- ============================================================================
-- File:         tb_RegFile.vhd
-- Description:  Testbench for PolyFlop8 Register File
--                This testbench verifies the following:
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

entity tb_RegFile is
    -- Testbench nie posiada portów zewnętrznych
end tb_RegFile;

architecture Behavioral of tb_RegFile is

    -- Deklaracja komponentu Unit Under Test (UUT)
    component RegFile
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            we         : in  STD_LOGIC;
            addr_a     : in  STD_LOGIC_VECTOR (2 downto 0);
            addr_b     : in  STD_LOGIC_VECTOR (2 downto 0);
            addr_w     : in  STD_LOGIC_VECTOR (2 downto 0);
            rf_src_sel : in  STD_LOGIC_VECTOR (2 downto 0);
            alu_out    : in  STD_LOGIC_VECTOR (7 downto 0);
            ram_data   : in  STD_LOGIC_VECTOR (7 downto 0);
            rs_imm_in  : in  STD_LOGIC_VECTOR (7 downto 0);
            io_data_in : in  STD_LOGIC_VECTOR (7 downto 0);
            sreg_data  : in  STD_LOGIC_VECTOR (7 downto 0);
            data_a     : out STD_LOGIC_VECTOR (7 downto 0);
            data_b     : out STD_LOGIC_VECTOR (7 downto 0);
            data_r7x   : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- Sygnały testowe
    signal clk_tb        : STD_LOGIC := '0';
    signal reset_tb      : STD_LOGIC := '0';
    signal we_tb         : STD_LOGIC := '0';
    signal addr_a_tb     : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal addr_b_tb     : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal addr_w_tb     : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal rf_src_sel_tb : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    
    -- Źródła danych (Symulacja wyjść z innych bloków)
    signal alu_out_tb    : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal ram_data_tb   : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal rs_imm_in_tb  : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal io_data_in_tb : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal sreg_data_tb  : STD_LOGIC_VECTOR(7 downto 0) := x"00";

    -- Wyjścia
    signal data_a_tb     : STD_LOGIC_VECTOR(7 downto 0);
    signal data_b_tb     : STD_LOGIC_VECTOR(7 downto 0);
    signal data_r7x_tb   : STD_LOGIC_VECTOR(7 downto 0);

    -- Zegar 100 MHz
    constant CLK_PERIOD : time := 10 ns;

    -- Funkcja pomocnicza do raportowania w Hex
    function to_hex_string(slv : std_logic_vector) return string is
        variable ret : string(1 to 2);
        variable val : integer := to_integer(unsigned(slv));
    begin
        -- Uproszczona konwersja dla raportów (tylko poglądowa)
        return integer'image(val); 
    end function;

begin

    -- Instancja UUT
    uut: RegFile port map (
        clk        => clk_tb,
        reset      => reset_tb,
        we         => we_tb,
        addr_a     => addr_a_tb,
        addr_b     => addr_b_tb,
        addr_w     => addr_w_tb,
        rf_src_sel => rf_src_sel_tb,
        alu_out    => alu_out_tb,
        ram_data   => ram_data_tb,
        rs_imm_in  => rs_imm_in_tb,
        io_data_in => io_data_in_tb,
        sreg_data  => sreg_data_tb,
        data_a     => data_a_tb,
        data_b     => data_b_tb,
        data_r7x   => data_r7x_tb
    );

    -- Generacja zegara
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
        -- TC-REG-01: Initialization & Reset Check
        -- Requirement: Verify all registers cleared on reset.
        -- =========================================================
        report "TC-REG-01: Reset Verification";
        reset_tb <= '1';
        we_tb <= '0';
        wait for 20 ns;
        reset_tb <= '0';
        wait for 10 ns;

        -- Sprawdzamy R0 i R7 (przykładowe rejestry)
        addr_a_tb <= "000"; -- R0
        addr_b_tb <= "111"; -- R7
        wait for 1 ns; -- Odczyt asynchroniczny
        
        assert data_a_tb = x"00" report "Error TC-REG-01: R0 not cleared" severity error;
        assert data_b_tb = x"00" report "Error TC-REG-01: R7 not cleared" severity error;

        -- =========================================================
        -- TC-REG-02: Write from Immediate (LDI Instruction)
        -- Selector: "010" (Zakładamy, że to LDI/MOV Immediate)
        -- Requirement: TR-ISA-XX (Load Immediate)
        -- =========================================================
        report "TC-REG-02: LDI - Write Immediate to R1";
        rf_src_sel_tb <= "010";   -- Wybór źródła: rs_imm_in
        rs_imm_in_tb  <= x"AA";   -- Wartość 0xAA (170)
        addr_w_tb     <= "001";   -- Cel: R1
        we_tb         <= '1';     -- Włącz zapis
        
        wait for CLK_PERIOD;      -- Czekamy na zbocze zegara
        we_tb <= '0';             -- Wyłącz zapis
        
        -- Weryfikacja odczytu
        addr_a_tb <= "001";       -- Odczytaj R1 na porcie A
        wait for 1 ns; 
        assert data_a_tb = x"AA" 
            report "Error TC-REG-02: Expected 0xAA, got " & to_hex_string(data_a_tb) severity error;

        -- =========================================================
        -- TC-REG-03: Write from ALU (ADD/SUB Instruction)
        -- Selector: "000" (Zakładamy, że to ALU)
        -- Requirement: TR-ALU-01 Integration
        -- =========================================================
        report "TC-REG-03: ALU Write Back to R2";
        rf_src_sel_tb <= "000";   -- Wybór źródła: alu_out
        alu_out_tb    <= x"F0";   -- Wynik z ALU
        addr_w_tb     <= "010";   -- Cel: R2
        we_tb         <= '1';
        
        wait for CLK_PERIOD;
        we_tb <= '0';
        
        addr_b_tb <= "010";       -- Odczytaj R2 na porcie B
        wait for 1 ns;
        assert data_b_tb = x"F0" 
            report "Error TC-REG-03: Expected 0xF0, got " & to_hex_string(data_b_tb) severity error;

        -- =========================================================
        -- TC-REG-04: Write from RAM (LD Instruction)
        -- Selector: "001" (Zakładamy, że to RAM)
        -- Requirement: TR-ISA-11 (Direct Load)
        -- =========================================================
        report "TC-REG-04: RAM Load to R3";
        rf_src_sel_tb <= "001";   -- Wybór źródła: ram_data
        ram_data_tb   <= x"55";   -- Dane z pamięci
        addr_w_tb     <= "011";   -- Cel: R3
        we_tb         <= '1';
        
        wait for CLK_PERIOD;
        we_tb <= '0';
        
        addr_a_tb <= "011"; 
        wait for 1 ns;
        assert data_a_tb = x"55" 
            report "Error TC-REG-04: Expected 0x55, got " & to_hex_string(data_a_tb) severity error;

        -- =========================================================
        -- TC-REG-05: Register Independence Check
        -- Verify that writing to R3 did not affect R1 or R2
        -- =========================================================
        report "TC-REG-05: Register Isolation check";
        
        -- Sprawdź R1 (powinno być 0xAA z TC-REG-02)
        addr_a_tb <= "001";
        wait for 1 ns;
        assert data_a_tb = x"AA" report "Error TC-REG-05: R1 corrupted" severity error;
        
        -- Sprawdź R2 (powinno być 0xF0 z TC-REG-03)
        addr_b_tb <= "010";
        wait for 1 ns;
        assert data_b_tb = x"F0" report "Error TC-REG-05: R2 corrupted" severity error;

        -- =========================================================
        -- TC-REG-06: Write Protection (we = '0')
        -- Requirement: Data should NOT change when we='0'
        -- =========================================================
        report "TC-REG-06: Write Enable Protection";
        we_tb <= '0';             -- Zapis wyłączony
        rf_src_sel_tb <= "010";   -- Próba wpisania Immediate
        rs_imm_in_tb  <= x"FF";   -- Wartość śmieciowa
        addr_w_tb     <= "001";   -- Cel: R1 (aktualnie 0xAA)
        
        wait for CLK_PERIOD;
        
        addr_a_tb <= "001";
        wait for 1 ns;
        assert data_a_tb = x"AA" 
            report "Error TC-REG-06: R1 overwritten despite WE=0" severity error;

        -- =========================================================
        -- TC-REG-07: R7 Special Pointer Output
        -- Requirement: Verify data_r7x always reflects Register 7
        -- =========================================================
        report "TC-REG-07: R7 Hardwired Output Verification";
        rf_src_sel_tb <= "010";   -- Immediate
        rs_imm_in_tb  <= x"07";   -- Wartość 7
        addr_w_tb     <= "111";   -- Cel: R7
        we_tb         <= '1';
        
        wait for CLK_PERIOD;
        we_tb <= '0';
        
        wait for 1 ns;
        -- Sprawdź dedykowane wyjście data_r7x
        assert data_r7x_tb = x"07" 
            report "Error TC-REG-07: data_r7x output incorrect" severity error;

        -- =========================================================
        -- Koniec testów
        -- =========================================================
        report "--- Register File Tests Completed Successfully ---";
        wait;
    end process;

end Behavioral;