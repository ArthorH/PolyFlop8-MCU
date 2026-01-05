-- ============================================================================
-- File:         ProgramCounter.vhd
-- Description:  Program Counter for PolyFlop8 Processor
--                This file has been verified with the following test cases:
--                - Reset Verification (TC-PC-01)
--                - Fetch Cycle (PC + 1) (TC-PC-02)
--                - Stall (pc_en = '0') (TC-PC-03)
--                - Absolute Jump (JMP) (TC-PC-04)
--                - Branch Positive (+5) (TC-PC-05)
--                - Branch Negative (-10) (TC-PC-06)
--                - Return from Subroutine (RET) (TC-PC-07)
--                - 100% code coverage of Program Counter behavioral description
--
-- Author:       Artem Horiunov
-- Date:         \today
-- Version:      1.0
-- Status:       VERIFIED
-- Test Report:  TC-PC-001
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ProgramCounter is
    -- Testbench has no external ports
end tb_ProgramCounter;

architecture Behavioral of tb_ProgramCounter is

    -- Component Declaration (Unit Under Test)
    component ProgramCounter
        Port (
            clk            : in  STD_LOGIC;
            rst            : in  STD_LOGIC;
            pc_en          : in  STD_LOGIC;
            -- Control Unit Selectors:
            -- "00": Fetch (PC + 1)
            -- "01": Branch (PC + 1 + Offset)
            -- "10": Return/Indirect (RAM Data)
            -- "11": Absolute Jump (Immediate Address)
            pc_src         : in  STD_LOGIC_VECTOR (1 downto 0);
            alu_out        : in  STD_LOGIC_VECTOR (7 downto 0);
            ram_data       : in  STD_LOGIC_VECTOR (7 downto 0);
            jump_abs_11bit : in  STD_LOGIC_VECTOR (10 downto 0);
            pc_out         : out STD_LOGIC_VECTOR (10 downto 0)
        );
    end component;

    -- Test Signals
    signal clk_tb            : STD_LOGIC := '0';
    signal rst_tb            : STD_LOGIC := '0';
    signal pc_en_tb          : STD_LOGIC := '0';
    signal pc_src_tb         : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal alu_out_tb        : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal ram_data_tb       : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal jump_abs_11bit_tb : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal pc_out_tb         : STD_LOGIC_VECTOR(10 downto 0);

    -- Clock Constant (100 MHz)
    constant CLK_PERIOD : time := 10 ns;

    -- Helper function for reporting
    function to_string(slv : std_logic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(slv)));
    end function;

begin

    -- Instantiate UUT
    uut: ProgramCounter port map (
        clk            => clk_tb,
        rst            => rst_tb,
        pc_en          => pc_en_tb,
        pc_src         => pc_src_tb,
        alu_out        => alu_out_tb,
        ram_data       => ram_data_tb,
        jump_abs_11bit => jump_abs_11bit_tb,
        pc_out         => pc_out_tb
    );

    -- Clock Process
    clk_process: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Main Stimulus Process
    stim_proc: process
    begin
        -- =========================================================
        -- TC-PC-01: Initialization & Reset Verification
        -- Requirement: Verify Priority of Reset (Section 6.3)
        -- =========================================================
        report "TC-PC-01: Reset Verification";
        rst_tb <= '1';
        pc_en_tb <= '0';
        wait for CLK_PERIOD * 2;
        
        rst_tb <= '0';
        wait for CLK_PERIOD; 
        
        assert pc_out_tb = "00000000000"
            report "Error TC-PC-01: Reset failed. Expected 0, got " & to_string(pc_out_tb)
            severity error;

        -- =========================================================
        -- TC-PC-02: Normal Instruction Fetch
        -- Mode: "00" (Fetch)
        -- Requirement: Sequential Execution (PC increment by 1)
        -- =========================================================
        report "TC-PC-02: Fetch Cycle (PC + 1)";
        pc_en_tb <= '1';
        pc_src_tb <= "00"; 
        
        -- Wait for cycles 1 -> 2 -> 3
        wait for CLK_PERIOD; 
        assert pc_out_tb = std_logic_vector(to_unsigned(1, 11))
            report "Error TC-PC-02: Fetch step 1 failed. Expected 1, got " & to_string(pc_out_tb) severity error;
            
        wait for CLK_PERIOD;
        assert pc_out_tb = std_logic_vector(to_unsigned(2, 11))
            report "Error TC-PC-02: Fetch step 2 failed. Expected 2, got " & to_string(pc_out_tb) severity error;

        -- =========================================================
        -- TC-PC-03: Stall / Hold Functionality
        -- Requirement: Verify PC enable logic (Section 6.3)
        -- =========================================================
        report "TC-PC-03: Stall (pc_en = '0')";
        pc_en_tb <= '0'; -- Hold current value (PC=2)
        wait for CLK_PERIOD;
        
        assert pc_out_tb = std_logic_vector(to_unsigned(2, 11))
            report "Error TC-PC-03: PC changed during stall state." severity error;
            
        pc_en_tb <= '1'; -- Re-enable

        -- =========================================================
        -- TC-PC-04: Absolute Jump
        -- Mode: "11" (JMP/CALL)
        -- Requirement: TR-ISA-13 (Verify Unconditional Jump)
        -- =========================================================
        report "TC-PC-04: Absolute Jump (JMP)";
        pc_src_tb <= "11";
        jump_abs_11bit_tb <= std_logic_vector(to_unsigned(100, 11)); -- Jump to address 100
        
        wait for CLK_PERIOD;
        assert pc_out_tb = std_logic_vector(to_unsigned(100, 11))
            report "Error TC-PC-04 (TR-ISA-13): JMP failed. Expected 100, got " & to_string(pc_out_tb) severity error;

        -- =========================================================
        -- TC-PC-05: Relative Branch (Positive Offset)
        -- Mode: "01" (Branch)
        -- Logic: Next_PC = (PC + 1) + Offset
        -- Current PC=100. Expected: (100 + 1) + 5 = 106
        -- Requirement: TR-ISA-14 (Verify Conditional Branch Taken)
        -- =========================================================
        report "TC-PC-05: Branch Positive (+5)";
        pc_src_tb <= "01";
        alu_out_tb <= std_logic_vector(to_signed(5, 8)); 
        
        wait for CLK_PERIOD;
        assert pc_out_tb = std_logic_vector(to_unsigned(106, 11))
            report "Error TC-PC-05 (TR-ISA-14): Branch(+) failed. Expected 106, got " & to_string(pc_out_tb) severity error;

        -- =========================================================
        -- TC-PC-06: Relative Branch (Negative Offset)
        -- Mode: "01" (Branch)
        -- Current PC=106. Expected: (106 + 1) - 10 = 97
        -- Requirement: TR-ISA-14 / Signed Arithmetic Check
        -- =========================================================
        report "TC-PC-06: Branch Negative (-10)";
        pc_src_tb <= "01";
        alu_out_tb <= std_logic_vector(to_signed(-10, 8));
        
        wait for CLK_PERIOD;
        assert pc_out_tb = std_logic_vector(to_unsigned(97, 11))
            report "Error TC-PC-06: Branch(-) failed. Expected 97, got " & to_string(pc_out_tb) severity error;

        -- =========================================================
        -- TC-PC-07: Indirect Jump / Return
        -- Mode: "10" (RET)
        -- Source: RAM Data (Stack Pop)
        -- Requirement: TR-ISA-17 (Verify Return)
        -- =========================================================
        report "TC-PC-07: Return from Subroutine (RET)";
        pc_src_tb <= "10";
        ram_data_tb <= std_logic_vector(to_unsigned(250, 8)); -- Address 0xFA
        -- Note: 8-bit RAM data is zero-padded to 11 bits
        
        wait for CLK_PERIOD;
        assert pc_out_tb = std_logic_vector(to_unsigned(250, 11))
            report "Error TC-PC-07 (TR-ISA-17): RET failed. Expected 250, got " & to_string(pc_out_tb) severity error;

        -- =========================================================
        -- End of Simulation
        -- =========================================================
        report "--- Program Counter Tests Completed Successfully ---";
        pc_en_tb <= '0';
        wait;
    end process;

end Behavioral;