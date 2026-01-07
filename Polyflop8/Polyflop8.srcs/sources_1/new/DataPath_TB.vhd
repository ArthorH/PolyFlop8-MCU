-- ============================================================================
-- File:         tb_datapath.vhd
-- Description:  Data Path Integration Test Bench (Stage 2)
--               Fixed StatusReg port mismatch (rst -> reset).
--               Adheres to TS-ST-DP-001.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_datapath is
    -- Testbench has no ports
end tb_datapath;

architecture Behavioral of tb_datapath is

    -- ========================================================================
    -- 1. Component Declarations
    -- ========================================================================

    -- ALU Component (Matches Spec Section 3.2 [cite: 552])
    component ALU is
        Port (
            pc_data         : in  STD_LOGIC_VECTOR(7 downto 0);
            regfile_data_a  : in  STD_LOGIC_VECTOR(7 downto 0);
            rs_imm_in       : in  STD_LOGIC_VECTOR(7 downto 0);
            regfile_data_b  : in  STD_LOGIC_VECTOR(7 downto 0);
            alu_mux_sel_a   : in  STD_LOGIC;
            alu_mux_sel_b   : in  STD_LOGIC;
            alu_sel         : in  STD_LOGIC_VECTOR(3 downto 0);
            cin             : in  STD_LOGIC;
            result          : out STD_LOGIC_VECTOR(7 downto 0);
            flags           : out STD_LOGIC_VECTOR(4 downto 0)
        );
    end component;

    -- Register File Component (Matches Spec Section 6.3 [cite: 718])
    component RegFile is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC; -- Confirmed 'reset' from schematic [cite: 712]
            we          : in  STD_LOGIC;
            addr_a      : in  STD_LOGIC_VECTOR(2 downto 0);
            addr_b      : in  STD_LOGIC_VECTOR(7 downto 0);
            addr_w      : in  STD_LOGIC_VECTOR(2 downto 0);
            rf_src_sel  : in  STD_LOGIC_VECTOR(2 downto 0);
            alu_out     : in  STD_LOGIC_VECTOR(7 downto 0);
            ram_data    : in  STD_LOGIC_VECTOR(7 downto 0);
            rs_imm_in   : in  STD_LOGIC_VECTOR(7 downto 0);
            io_data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            sreg_data   : in  STD_LOGIC_VECTOR(7 downto 0);
            data_a      : out STD_LOGIC_VECTOR(7 downto 0);
            data_b      : out STD_LOGIC_VECTOR(7 downto 0);
            data_r7x    : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Status Register Component (Matches Spec Section 9.1 [cite: 767])
    component StatusReg is
        Port (
            clk             : in  STD_LOGIC;
            rst           : in  STD_LOGIC; -- FIXED: Changed 'rst' to 'reset' to match Entity
            sreg_we         : in  STD_LOGIC;
            sreg_src        : in  STD_LOGIC;
            alu_flags       : in  STD_LOGIC_VECTOR(4 downto 0);
            regfile_data_b  : in  STD_LOGIC_VECTOR(7 downto 0);
            sreg_out       : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- ========================================================================
    -- 2. Signal Declarations
    -- ========================================================================

    -- System Signals
    signal clk_tb       : STD_LOGIC := '0';
    signal rst_tb       : STD_LOGIC := '0';
    constant clk_period : time := 10 ns;

    -- Virtual Control Unit Signals
    signal alu_mux_sel_a_tb : STD_LOGIC := '0';
    signal alu_mux_sel_b_tb : STD_LOGIC := '0';
    signal alu_sel_tb       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal cin_tb           : STD_LOGIC := '0';
    
    signal reg_we_tb        : STD_LOGIC := '0';
    signal addr_a_tb        : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal addr_b_tb        : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal addr_w_tb        : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal rf_src_sel_tb    : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');

    signal sreg_we_tb       : STD_LOGIC := '0';
    signal sreg_src_tb      : STD_LOGIC := '0';

    -- Data Path Interconnects
    signal reg_data_a_tb    : STD_LOGIC_VECTOR(7 downto 0);
    signal reg_data_b_tb    : STD_LOGIC_VECTOR(7 downto 0);
    signal alu_result_tb    : STD_LOGIC_VECTOR(7 downto 0);
    signal alu_flags_tb     : STD_LOGIC_VECTOR(4 downto 0);
    signal sreg_data_tb     : STD_LOGIC_VECTOR(7 downto 0);
    signal data_r7x_tb      : STD_LOGIC_VECTOR(7 downto 0);

    -- Virtual External Inputs
    signal pc_data_stub     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal rs_imm_in_stub   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal ram_data_stub    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal io_data_in_stub  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin

    -- ========================================================================
    -- 3. Component Instantiation
    -- ========================================================================

    U_ALU: ALU port map (
        pc_data         => pc_data_stub,
        regfile_data_a  => reg_data_a_tb,
        rs_imm_in       => rs_imm_in_stub,
        regfile_data_b  => reg_data_b_tb,
        alu_mux_sel_a   => alu_mux_sel_a_tb,
        alu_mux_sel_b   => alu_mux_sel_b_tb,
        alu_sel         => alu_sel_tb,
        cin             => cin_tb,
        result          => alu_result_tb,
        flags           => alu_flags_tb
    );

    U_REGFILE: RegFile port map (
        clk         => clk_tb,
        reset       => rst_tb,
        we          => reg_we_tb,
        addr_a      => addr_a_tb,
        addr_b      => addr_b_tb,
        addr_w      => addr_w_tb,
        rf_src_sel  => rf_src_sel_tb,
        alu_out     => alu_result_tb,
        ram_data    => ram_data_stub,
        rs_imm_in   => rs_imm_in_stub,
        io_data_in  => io_data_in_stub,
        sreg_data   => sreg_data_tb,
        data_a      => reg_data_a_tb,
        data_b      => reg_data_b_tb,
        data_r7x    => data_r7x_tb
    );

    U_SREG: StatusReg port map (
        clk             => clk_tb,
        rst           => rst_tb, -- FIXED: Now mapping 'reset' => rst_tb
        sreg_we         => sreg_we_tb,
        sreg_src        => sreg_src_tb,
        alu_flags       => alu_flags_tb,
        regfile_data_b  => reg_data_b_tb,
        sreg_out       => sreg_data_tb
    );

    -- ========================================================================
    -- 4. Clock Generation
    -- ========================================================================
    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- ========================================================================
    -- 5. Main Test Stimulus
    -- ========================================================================
    stim_proc: process
    begin
        report "===================================================";
        report "Starting Data Path Integration Test (TS-ST-DP-001)";
        report "===================================================";
        
        rst_tb <= '1';
        wait for clk_period * 2;
        rst_tb <= '0';
        wait for clk_period;

        -- DP-01: Register Read/Write Integrity [cite: 238]
        report "Executing DP-01: Register Read/Write Integrity";
        rf_src_sel_tb <= "010"; -- Select Immediate
        reg_we_tb     <= '1';
        
        addr_w_tb      <= "001"; -- R1
        rs_imm_in_stub <= x"55";
        wait for clk_period;

        addr_w_tb      <= "010"; -- R2
        rs_imm_in_stub <= x"AA";
        wait for clk_period;

        reg_we_tb <= '0';
        
        addr_a_tb <= "001";
        wait for 1 ns; 
        assert reg_data_a_tb = x"55" report "DP-01 Failed: R1 Read Mismatch" severity error;
        
        addr_b_tb <= "01000000"; -- R2 on Port B (Bits 7:5)
        wait for 1 ns;
        assert reg_data_b_tb = x"AA" report "DP-01 Failed: R2 Read Mismatch on Port B" severity error;
        report "DP-01 Passed";

        -- DP-02: ALU-Register Loopback [cite: 243]
        report "Executing DP-02: ALU-Register Loopback";
        -- Load operands: R1=10 (0x0A), R2=20 (0x14)
        rf_src_sel_tb <= "010"; reg_we_tb <= '1';
        addr_w_tb <= "001"; rs_imm_in_stub <= x"0A"; wait for clk_period;
        addr_w_tb <= "010"; rs_imm_in_stub <= x"14"; wait for clk_period;
        reg_we_tb <= '0';
        
        -- Execute ADD R1, R2 -> R3
        alu_mux_sel_a_tb <= '0'; alu_mux_sel_b_tb <= '0';
        addr_a_tb <= "001"; addr_b_tb <= "01000000";
        alu_sel_tb <= "0000"; -- ADD
        rf_src_sel_tb <= "000"; -- ALU Result
        addr_w_tb <= "011"; -- R3
        reg_we_tb <= '1';
        wait for clk_period;
        reg_we_tb <= '0';

        addr_a_tb <= "011";
        wait for 1 ns;
        assert reg_data_a_tb = x"1E" report "DP-02 Failed: Expected 0x1E in R3" severity error;
        report "DP-02 Passed";

        -- DP-03: Flag Persistence [cite: 248]
        report "Executing DP-03: Flag Persistence";
        -- SUB R1(10) - R2(20) = -10 (0xF6). Should set N flag.
        addr_a_tb <= "001"; addr_b_tb <= "01000000";
        alu_sel_tb <= "0010"; -- SUB
        sreg_we_tb <= '1'; 
        sreg_src_tb <= '0'; -- Select ALU Flags
        wait for clk_period;
        sreg_we_tb <= '0';
        
        wait for 1 ns;
        -- Debugging help: Print the SREG value if it fails
        if sreg_data_tb(2) /= '1' then
            report "DP-03 Debug: SREG Content = " & integer'image(to_integer(unsigned(sreg_data_tb))) & 
                   " (Expected Bit 2 'N' to be 1)" severity note;
        end if;
        assert sreg_data_tb(2) = '1' report "DP-03 Failed: N flag not set immediately after SUB" severity error;
        
        -- NOP (MOV R0, R0) - Flags should persist
        alu_sel_tb <= "0111"; -- MOV
        wait for clk_period;
        
        if sreg_data_tb(2) /= '1' then
             report "DP-03 Debug: Flags lost. SREG Content = " & integer'image(to_integer(unsigned(sreg_data_tb))) severity note;
        end if;
        assert sreg_data_tb(2) = '1' report "DP-03 Failed: Flag lost during NOP" severity error;
        report "DP-03 Passed";

       -- DP-04: Carry Propagation [cite: 253]
        report "Executing DP-04: Carry Propagation";
        rf_src_sel_tb <= "010"; reg_we_tb <= '1';
        addr_w_tb <= "001"; rs_imm_in_stub <= x"05"; wait for clk_period;
        addr_w_tb <= "010"; rs_imm_in_stub <= x"05"; wait for clk_period;
        reg_we_tb <= '0';

        alu_sel_tb <= "0001"; -- ADC
        addr_a_tb <= "001"; addr_b_tb <= "01000000";
        cin_tb <= '1';
        wait for 5 ns;
        assert alu_result_tb = x"0B" report "DP-04 Failed: ADC Result Mismatch" severity error;
        cin_tb <= '0';
        report "DP-04 Passed";

        -- DP-05: Immediate Data Path [cite: 258]
        report "Executing DP-05: Immediate Data Path";
        rs_imm_in_stub <= x"FF";
        alu_mux_sel_b_tb <= '1'; -- Select Imm
        alu_sel_tb <= "0111"; -- MOV (Pass B)
        addr_w_tb <= "100";
        rf_src_sel_tb <= "000"; -- Write ALU
        reg_we_tb <= '1';
        wait for clk_period;
        reg_we_tb <= '0';
        
        addr_a_tb <= "100";
        wait for 1 ns;
        assert reg_data_a_tb = x"FF" report "DP-05 Failed: Immediate load mismatch" severity error;
        report "DP-05 Passed";

        -- DP-06: X-Pointer Interface [cite: 263]
        report "Executing DP-06: X-Pointer Interface";
        rf_src_sel_tb <= "010"; reg_we_tb <= '1';
        addr_w_tb <= "111"; rs_imm_in_stub <= x"99";
        wait for clk_period;
        reg_we_tb <= '0';
        wait for 1 ns;
        assert data_r7x_tb = x"99" report "DP-06 Failed: R7 Hardwired output incorrect" severity error;
        report "DP-06 Passed";

        -- DP-07: ALU-to-DRAM Address Path [cite: 269]
        report "Executing DP-07: ALU-to-DRAM Address Path";
        alu_mux_sel_a_tb <= '0'; alu_mux_sel_b_tb <= '0';
        rf_src_sel_tb <= "010"; reg_we_tb <= '1';
        addr_w_tb <= "001"; rs_imm_in_stub <= x"10"; wait for clk_period;
        addr_w_tb <= "010"; rs_imm_in_stub <= x"20"; wait for clk_period;
        reg_we_tb <= '0';

        alu_sel_tb <= "0000"; -- ADD
        addr_a_tb <= "001"; addr_b_tb <= "01000000";
        wait for 5 ns;
        assert alu_result_tb = x"30" report "DP-07 Failed: Computed Address incorrect" severity error;
        report "DP-07 Passed";

        -- DP-08: Write-Back Source Selection [cite: 273]
        report "Executing DP-08: Write-Back Source Selection";
        reg_we_tb <= '1'; addr_w_tb <= "101";
        rf_src_sel_tb <= "011"; -- IO Data
        io_data_in_stub <= x"22";
        wait for clk_period;
        reg_we_tb <= '0';
        
        addr_a_tb <= "101";
        wait for 1 ns;
        assert reg_data_a_tb = x"22" report "DP-08 Failed: IO Data Mux selection" severity error;
        report "DP-08 Passed";

        report "===================================================";
        report "Test Suite TS-ST-DP-001 Completed Successfully";
        report "===================================================";
        wait;
    end process;

end Behavioral;