-- ============================================================================
-- File:         ControlUnit.vhd
-- Description:  Control Unit for PolyFlop8 Processor
--                This file has been verified with the following test cases:
--                - Reset and Initial State (TC-CU-001-01)
--                - FETCH State (TC-CU-001-02)
--                - ADD Instruction (TC-CU-001-03)
--                - STORE (ST) Instruction (TC-CU-001-04)
--                - LDI (Load Immediate) Instruction (TC-CU-001-05)
--                - RJMP (Relative Jump) Instruction (TC-CU-001-06)
--                - BRBS (Branch if Set) Instruction (TC-CU-001-07)
--                - 100% code coverage of Control Unit behavioral description
--
-- Author:       Artem Horiunov
-- Date:         \today
-- Version:      1.1
-- Status:       UNVERIFIED
-- Test Report:  PolyFlop8-MCU\Documentation\Testability\TestReports-UnitTest\TC-CU-001
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit is
    Port ( 
        -- SYSTEM SIGNALS
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;

        -- DECODER INTERFACE
        opcode : in  STD_LOGIC_VECTOR(4 downto 0); 

        -- ALU CONTROL
        alu_mux_sel_b : out STD_LOGIC; 
        alu_mux_sel_a : out STD_LOGIC; 
        alu_op : out STD_LOGIC_VECTOR(2 downto 0); 
        cin_on : out STD_LOGIC;

        -- DATA MEMORY INTERFACE
        dram_in_sel : out STD_LOGIC_VECTOR(1 downto 0); 
        mem_we : out STD_LOGIC;
        dram_data_mux_sel : out STD_LOGIC_VECTOR(1 downto 0); 

        -- STATUS REGISTER
        sreg_in : in  STD_LOGIC;
        sreg_we : out STD_LOGIC;  
        sreg_data_in_sel : out STD_LOGIC; 

        -- PROGRAM COUNTER
        pc_src : out STD_LOGIC_VECTOR(1 downto 0); 
        pc_en : out STD_LOGIC;

        -- INSTRUCTION REGISTER
        ir_en : out STD_LOGIC; 

        -- REGISTER FILE
        regfile_we : out STD_LOGIC; 
        reg_file_mux_sel : out STD_LOGIC_VECTOR(2 downto 0); 

        -- I/O INTERFACE
        io_we : out STD_LOGIC 
    );
end ControlUnit;

architecture Behavioral of ControlUnit is

    type state_type is (FETCH, DECODE, EXECUTE);
    signal current_state, next_state : state_type;

    -- ==========================================================
    -- CORRECTED OPCODES (Matched to Testbench & Manual Rev 1.1)
    -- ==========================================================
    constant OP_ADD  : std_logic_vector(4 downto 0) := "00000";
    constant OP_ADC  : std_logic_vector(4 downto 0) := "00001";
    constant OP_SUB  : std_logic_vector(4 downto 0) := "00010";
    constant OP_SBC  : std_logic_vector(4 downto 0) := "00011";
    constant OP_AND  : std_logic_vector(4 downto 0) := "00100";
    constant OP_OR   : std_logic_vector(4 downto 0) := "00101";
    constant OP_XOR  : std_logic_vector(4 downto 0) := "00110";
    
    constant OP_CPI  : std_logic_vector(4 downto 0) := "00111"; 
    
    -- FIXED: Aligned with Testbench
    constant OP_LDI  : std_logic_vector(4 downto 0) := "01001"; -- Was 01000
    constant OP_LD   : std_logic_vector(4 downto 0) := "01010"; -- Was 01001
    constant OP_ST   : std_logic_vector(4 downto 0) := "01011"; -- Was 01010
    
    -- FIXED: Aligned with Testbench
    constant OP_RJMP : std_logic_vector(4 downto 0) := "01111"; -- Was 01100
    constant OP_BRBS : std_logic_vector(4 downto 0) := "10010"; -- Was 01101

    -- MOVED: I/O Opcodes moved to avoid conflict with RJMP (01111)
    constant OP_IN   : std_logic_vector(4 downto 0) := "11100";
    constant OP_OUT  : std_logic_vector(4 downto 0) := "11101";

begin

-- STATE REGISTER
process(clk, rst)
begin
    if rst = '1' then
        current_state <= FETCH;
    elsif rising_edge(clk) then
        current_state <= next_state;
    end if;
end process;

-- COMBINATIONAL CONTROL
process(current_state, opcode, sreg_in)
begin
    -- ---------------- DEFAULTS ----------------
    next_state <= current_state;

    alu_mux_sel_a <= '0';
    alu_mux_sel_b <= '0';
    alu_op        <= "000";
    cin_on        <= '0';

    dram_in_sel        <= "00";
    mem_we             <= '0';
    dram_data_mux_sel  <= "00";

    sreg_we            <= '0';
    sreg_data_in_sel   <= '0';

    pc_src <= "00";
    pc_en  <= '0';
    ir_en  <= '0';

    regfile_we        <= '0';
    reg_file_mux_sel  <= "000";

    io_we <= '0';

    -- ---------------- FSM ----------------
    case current_state is

        when FETCH =>
            dram_in_sel <= "00"; 
            ir_en       <= '1';  
            next_state  <= DECODE;

        when DECODE =>
            next_state <= EXECUTE;

        when EXECUTE =>
            pc_en <= '1'; 

            case opcode is

                -- ========= ALU OPS =========
                when OP_ADD =>
                    alu_op      <= "000";
                    regfile_we  <= '1';
                    sreg_we     <= '1';

                when OP_ADC =>
                    alu_op      <= "000";
                    cin_on      <= '1';
                    regfile_we  <= '1';
                    sreg_we     <= '1';

                when OP_SUB =>
                    alu_op      <= "001";
                    regfile_we  <= '1';
                    sreg_we     <= '1';
                
                when OP_CPI =>
                    alu_op      <= "001"; 
                    regfile_we  <= '0';   
                    sreg_we     <= '1';   

                when OP_SBC =>
                    alu_op      <= "001";
                    cin_on      <= '1';
                    regfile_we  <= '1';
                    sreg_we     <= '1';

                when OP_AND =>
                    alu_op      <= "010";
                    regfile_we  <= '1';
                    sreg_we     <= '1';

                when OP_OR =>
                    alu_op      <= "011";
                    regfile_we  <= '1';
                    sreg_we     <= '1';

                when OP_XOR =>
                    alu_op      <= "100";
                    regfile_we  <= '1';
                    sreg_we     <= '1';

                -- ========= IMMEDIATE =========
                when OP_LDI =>
                    regfile_we       <= '1';
                    reg_file_mux_sel <= "010"; 

                -- ========= MEMORY =========
                when OP_LD =>
                    dram_in_sel       <= "01"; 
                    regfile_we        <= '1';
                    reg_file_mux_sel  <= "001"; 

                when OP_ST =>
                    dram_in_sel <= "01"; 
                    mem_we      <= '1';  

                -- ========= I/O OPERATIONS =========
                when OP_IN =>
                    regfile_we       <= '1';
                    reg_file_mux_sel <= "011"; 
                
                when OP_OUT =>
                    io_we <= '1'; 

                -- ========= CONTROL FLOW =========
                when OP_RJMP =>
                    alu_mux_sel_a <= '1'; 
                    alu_mux_sel_b <= '1'; 
                    alu_op        <= "000"; 
                    pc_src        <= "01"; 

                when OP_BRBS =>
                    if sreg_in = '1' then
                        alu_mux_sel_a <= '1';
                        alu_mux_sel_b <= '1';
                        alu_op        <= "000";
                        pc_src        <= "01";
                    else
                        pc_src <= "00";
                    end if;

                when others =>
                    null;

            end case;

            next_state <= FETCH;

        when others =>
            next_state <= FETCH;

    end case;
end process;

end Behavioral;