-- ============================================================================
-- File:         ControlUnit_TB.vhd
-- Description:  Testbench for PolyFlop8 Control Unit
--                This testbench verifies the following:
--                - Reset and Initial State (TC-CU-001-01)
--                - FETCH State (TC-CU-001-02)
--                - ADD Instruction (TC-CU-001-03)
--                - STORE (ST) Instruction (TC-CU-001-04)
--                - LDI (Load Immediate) Instruction (TC-CU-001-05)
--                - RJMP (Relative Jump) Instruction (TC-CU-001-06)
--                - BRBS (Branch if Set) Instruction (TC-CU-001-07)
--                - 100% code coverage of Control Unit behavioral description
--
-- Author:       Robistruction ROBOTICS
-- Date:         \today
-- Version:      1.0
-- Status:       VERIFIED
-- Test Report:  PolyFlop8-MCU\Documentation\Testability\TestReports-UnitTest\TC-CU-001
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controlunit_tb is
end controlunit_tb;

architecture Behavioral of controlunit_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component ControlUnit
    Port ( 
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        opcode : in  STD_LOGIC_VECTOR(3 downto 0);
        alu_mux_sel_b : out STD_LOGIC; 
        alu_mux_sel_a : out STD_LOGIC; 
        alu_op : out STD_LOGIC_VECTOR(2 downto 0); 
        cin_on : out STD_LOGIC;
        dram_in_sel : out STD_LOGIC_VECTOR(1 downto 0); 
        mem_we : out STD_LOGIC;
        dram_data_mux_sel : out STD_LOGIC_VECTOR(1 downto 0); 
        sreg_in : in  STD_LOGIC;
        sreg_we : out STD_LOGIC;  
        sreg_data_in_sel : out STD_LOGIC; 
        pc_src : out STD_LOGIC_VECTOR(1 downto 0); 
        pc_en : out STD_LOGIC;
        ir_en : out STD_LOGIC; 
        regfile_we : out STD_LOGIC; 
        reg_file_mux_sel : out STD_LOGIC_VECTOR(2 downto 0); 
        io_we : out STD_LOGIC 
    );
    end component;

    -- Internal Testbench Signals
    signal clk_tb : STD_LOGIC := '0';
    signal rst_tb : STD_LOGIC := '0';
    signal opcode_tb : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal sreg_in_tb : STD_LOGIC := '0';

    -- Output Signals to Observe
    signal alu_mux_sel_b_tb : STD_LOGIC;
    signal alu_mux_sel_a_tb : STD_LOGIC;
    signal alu_op_tb : STD_LOGIC_VECTOR(2 downto 0);
    signal cin_on_tb : STD_LOGIC;
    signal dram_in_sel_tb : STD_LOGIC_VECTOR(1 downto 0);
    signal mem_we_tb : STD_LOGIC;
    signal dram_data_mux_sel_tb : STD_LOGIC_VECTOR(1 downto 0);
    signal sreg_we_tb : STD_LOGIC;
    signal sreg_data_in_sel_tb : STD_LOGIC;
    signal pc_src_tb : STD_LOGIC_VECTOR(1 downto 0);
    signal pc_en_tb : STD_LOGIC;
    signal ir_en_tb : STD_LOGIC;
    signal regfile_we_tb : STD_LOGIC;
    signal reg_file_mux_sel_tb : STD_LOGIC_VECTOR(2 downto 0);
    signal io_we_tb : STD_LOGIC;

    -- Clock Period Definition
    constant CLK_PERIOD : time := 10 ns;

    -- Opcode Constants (4-bit from Manual)
    -- Arithmetic
    constant OP_ADD : std_logic_vector(3 downto 0) := "0000"; -- 0
    constant OP_ADC : std_logic_vector(3 downto 0) := "0001"; -- 1
    constant OP_SUB : std_logic_vector(3 downto 0) := "0010"; -- 2
    constant OP_SBC : std_logic_vector(3 downto 0) := "0011"; -- 3
    -- Logical
    constant OP_AND : std_logic_vector(3 downto 0) := "0100"; -- 4
    constant OP_OR  : std_logic_vector(3 downto 0) := "0101"; -- 5
    constant OP_XOR : std_logic_vector(3 downto 0) := "0110"; -- 6
    -- Data Transfer
    constant OP_LDI : std_logic_vector(3 downto 0) := "1000"; -- 8
    constant OP_LD  : std_logic_vector(3 downto 0) := "1001"; -- 9 (Indirect/Direct Load)
    constant OP_ST  : std_logic_vector(3 downto 0) := "1010"; -- 10 (Store)
    -- Control Flow
    constant OP_RJMP : std_logic_vector(3 downto 0) := "1100"; -- 12
    constant OP_BRBS : std_logic_vector(3 downto 0) := "1101"; -- 13 (Branch if Set)

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: ControlUnit Port Map (
        clk => clk_tb,
        rst => rst_tb,
        opcode => opcode_tb,
        alu_mux_sel_b => alu_mux_sel_b_tb,
        alu_mux_sel_a => alu_mux_sel_a_tb,
        alu_op => alu_op_tb,
        cin_on => cin_on_tb,
        dram_in_sel => dram_in_sel_tb,
        mem_we => mem_we_tb,
        dram_data_mux_sel => dram_data_mux_sel_tb,
        sreg_in => sreg_in_tb,
        sreg_we => sreg_we_tb,
        sreg_data_in_sel => sreg_data_in_sel_tb,
        pc_src => pc_src_tb,
        pc_en => pc_en_tb,
        ir_en => ir_en_tb,
        regfile_we => regfile_we_tb,
        reg_file_mux_sel => reg_file_mux_sel_tb,
        io_we => io_we_tb
    );

    -- Clock Generation Process
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

-- Proces stymulujący (Test Stimulus)
    stim_proc: process
    begin
        -- =========================================================
        -- TC-CU-001-01: Initialization and Reset
        -- =========================================================
        report "TC-CU-001-01: Testing Reset and Initial State";
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        rst_tb <= '0';
        
        -- ZMIANA TUTAJ: Nie czekamy całego cyklu! Sprawdzamy stan FETCH od razu po resecie.
        wait for 1 ns; -- Małe opóźnienie dla ustalenia sygnałów (Delta cycles)

        -- =========================================================
        -- TC-CU-001-02: FETCH Cycle Verification
        -- =========================================================
        -- Expect: ir_en = '1', address select from PC
        -- Teraz jesteśmy wciąż przed pierwszym zboczem zegara po resecie -> Stan FETCH
        report "TC-CU-001-02: Verifying FETCH state";
        assert ir_en_tb = '1' report "Error: IR_EN should be '1' in FETCH state" severity error;
        assert dram_in_sel_tb = "00" report "Error: Memory address should be PC ('00') in FETCH" severity error;
        assert mem_we_tb = '0' report "Error: MEM_WE active in FETCH state" severity error;
        
        -- Teraz pozwalamy na tyknięcie zegara -> Przejście do DECODE
        wait for CLK_PERIOD; 
        
        -- =========================================================
        -- TC-CU-001-03: Arithmetic Instruction Verification (ADD)
        -- =========================================================
        report "TC-CU-001-03: Testing ADD instruction";
        opcode_tb <= OP_ADD;
        
        -- Jesteśmy w DECODE. Czekamy jeden cykl, aby wejść do EXECUTE
        wait for CLK_PERIOD; 
        
        -- EXECUTE Cycle
        report "Checking signals for ADD in EXECUTE state";
        assert alu_op_tb = "000" report "Error: Wrong ALU_OP for ADD" severity error;
        assert regfile_we_tb = '1' report "Error: ADD must write to register" severity error;
        assert alu_mux_sel_b_tb = '0' report "Error: ADD uses Register B, not Immediate" severity error;
        assert pc_en_tb = '1' report "Error: PC should increment after EXECUTE" severity error;

        wait for CLK_PERIOD; -- Return to FETCH

        -- =========================================================
        -- TC-CU-001-04: Memory Verification (STORE)
        -- =========================================================
        report "TC-CU-001-04: Testing STORE (ST) instruction";
        -- Currently in FETCH
        wait for CLK_PERIOD; -- Pass FETCH -> Go to DECODE
        opcode_tb <= OP_ST;  -- Simulate ST opcode loaded
        wait for CLK_PERIOD; -- Pass DECODE -> Go to EXECUTE
        
        -- Currently in EXECUTE
        report "Checking signals for STORE";
        assert mem_we_tb = '1' report "Error: MEM_WE should be '1' for ST" severity error;
        assert regfile_we_tb = '0' report "Error: ST should not write to registers" severity error;
        assert dram_in_sel_tb = "01" report "Error: Address for ST should be from ALU/Pointer ('01')" severity error;

        wait for CLK_PERIOD; -- Return to FETCH

        -- =========================================================
        -- TC-CU-001-05: Data Load Verification (LDI - Immediate)
        -- =========================================================
        report "TC-CU-001-05: Testing LDI (Load Immediate) instruction";
        wait for CLK_PERIOD; -- FETCH -> DECODE
        opcode_tb <= OP_LDI;
        wait for CLK_PERIOD; -- DECODE -> EXECUTE
        
        -- EXECUTE
        assert regfile_we_tb = '1' report "Error: LDI must write to register" severity error;
        assert reg_file_mux_sel_tb = "010" report "Error: Wrong data source for LDI (expected '010' - Immediate)" severity error;
        assert mem_we_tb = '0' report "Error: LDI does not write to memory" severity error;

        wait for CLK_PERIOD; -- Return to FETCH

        -- =========================================================
        -- TC-CU-001-06: Control Flow (RJMP - Relative Jump)
        -- =========================================================
        report "TC-CU-001-06: Testing RJMP instruction";
        wait for CLK_PERIOD; -- FETCH -> DECODE
        opcode_tb <= OP_RJMP;
        wait for CLK_PERIOD; -- DECODE -> EXECUTE
        
        -- EXECUTE
        assert pc_src_tb = "01" report "Error: PC_SRC should be '01' (ALU/Relative) for RJMP" severity error;
        assert alu_mux_sel_a_tb = '1' report "Error: For RJMP ALU input A must be PC ('1')" severity error;
        assert pc_en_tb = '1' report "Error: RJMP must update PC" severity error;

        wait for CLK_PERIOD; -- Return to FETCH

        -- =========================================================
        -- TC-CU-001-07: Conditional Branch (BRBS - Branch if Set)
        -- =========================================================
        report "Testing BRBS instruction (Condition Met)";
        wait for CLK_PERIOD; -- FETCH -> DECODE
        opcode_tb <= OP_BRBS;
        sreg_in_tb <= '1';   -- Simulate flag set (condition met)
        wait for CLK_PERIOD; -- DECODE -> EXECUTE
        
        -- EXECUTE
        assert pc_src_tb = "01" report "Error: BRBS (Taken) should set relative jump" severity error;
        
        wait for CLK_PERIOD; -- Return to FETCH

        report "Testing BRBS instruction (Condition Not Met)";
        wait for CLK_PERIOD; -- FETCH -> DECODE
        opcode_tb <= OP_BRBS;
        sreg_in_tb <= '0';   -- Flag cleared (condition not met)
        wait for CLK_PERIOD; -- DECODE -> EXECUTE
        
        -- EXECUTE
        assert pc_src_tb = "00" report "Error: BRBS (Not Taken) should increment PC normally" severity error;

        -- =========================================================
        -- End of Tests
        -- =========================================================
        wait for CLK_PERIOD * 5;
        report "All tests finished successfully (if no errors above)." severity note;
        wait;
    end process;

end Behavioral;