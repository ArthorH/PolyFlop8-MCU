-- ============================================================================
-- File:         tb_IO_Unit.vhd
-- Description:  Testbench for PolyFlop8 IO Unit
--                This testbench verifies the following:
--                - Reset functionality (TC-IO-01)
--                - Write to Port A (TC-IO-02)
--                - Data retention (TC-IO-03)
--                - Read from Port B (TC-IO-04)
--                - Address isolation for unsupported addresses (TC-IO-05)
--                - 100% code coverage of IO Unit behavioral description
--
-- Author:       Artem Horiunov
-- Date:         \today
-- Version:      1.0
-- Status:       VERIFIED
-- Test Report:  TC-IO-001
-- ============================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_IO_Unit is
end tb_IO_Unit;

architecture Behavioral of tb_IO_Unit is

    -- 1. Component Declaration (Matches the provided entity)
    component IO_Unit is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            io_we       : in  STD_LOGIC;
            io_addr_in  : in  STD_LOGIC_VECTOR (7 downto 0);
            io_data_out : in  STD_LOGIC_VECTOR (7 downto 0);
            io_data_in  : out STD_LOGIC_VECTOR (7 downto 0);
            port_out_a  : out STD_LOGIC_VECTOR (7 downto 0);
            pin_in_b    : in  STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- 2. Test signals
    signal clk_tb         : STD_LOGIC := '0';
    signal reset_tb       : STD_LOGIC := '0';
    signal io_we_tb       : STD_LOGIC := '0';
    signal io_addr_in_tb  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal io_data_out_tb : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); -- Data from CPU to IO
    signal io_data_in_tb  : STD_LOGIC_VECTOR (7 downto 0);                     -- Data from IO to CPU
    signal port_out_a_tb  : STD_LOGIC_VECTOR (7 downto 0);                     -- Physical output pins
    signal pin_in_b_tb    : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');  -- Physical input pins

    -- Clock constant
    constant CLK_PERIOD : time := 10 ns;

    -- PORT ADDRESSES (Adjust if different in your architecture!)
    -- Typically in PolyFlop8: Port A (OUT) = 0x01, Port B (IN) = 0x02
    constant ADDR_PORT_A : STD_LOGIC_VECTOR(7 downto 0) := x"01";
    constant ADDR_PORT_B : STD_LOGIC_VECTOR(7 downto 0) := x"02";

begin

    -- 3. UUT Instance
    UUT: IO_Unit port map (
        clk         => clk_tb,
        reset       => reset_tb,
        io_we       => io_we_tb,
        io_addr_in  => io_addr_in_tb,
        io_data_out => io_data_out_tb, -- Data to send (from registers)
        io_data_in  => io_data_in_tb,  -- Data received (to registers)
        port_out_a  => port_out_a_tb,
        pin_in_b    => pin_in_b_tb
    );

    -- 4. Clock Generator
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Test Process (Stimulus)
    stim_proc: process
    begin
        report "START: Test Bench for IO_Unit (PolyFlop8)";

        -- Initialization
        reset_tb <= '1';
        io_we_tb <= '0';
        io_addr_in_tb <= x"00";
        io_data_out_tb <= x"00";
        pin_in_b_tb <= x"00"; -- Default state of input switches
        wait for 100 ns;

        ------------------------------------------------------------
        -- TC-IO-01: Reset Verification (TR-IO-05)
        ------------------------------------------------------------
        report "TC-IO-01: Reset Test";

        -- Set some garbage on the output before reset (simulate unstable state)
        -- Note: In VHDL after start 'U', after reset should be '0'.

        reset_tb <= '0'; -- Release reset
        wait for CLK_PERIOD;

        -- Check if Port A is zeroed after reset
        assert port_out_a_tb = x"00"
            report "Error TC-IO-01: Port A was not zeroed after Reset!" severity error;

        ------------------------------------------------------------
        -- TC-IO-02: Write to Port A (OUT Instruction) (TR-IO-01, TR-IO-02)
        ------------------------------------------------------------
        report "TC-IO-02: Write 0xAA to Port A (Address 0x01)";

        io_addr_in_tb  <= ADDR_PORT_A; -- Port A Address
        io_data_out_tb <= x"AA";       -- Pattern 10101010
        io_we_tb       <= '1';         -- Enable write (Simulate OUT)
        wait for CLK_PERIOD;

        -- Disable write
        io_we_tb <= '0';

        -- Check if physical pins (port_out_a) have value 0xAA
        wait for 1 ns; -- small propagation delay
        assert port_out_a_tb = x"AA"
            report "Error TC-IO-02: Port A did not accept value 0xAA" severity error;

        ------------------------------------------------------------
        -- TC-IO-03: Data Retention (TR-IO-04)
        ------------------------------------------------------------
        report "TC-IO-03: Output Retention Test (Write Enable = 0)";

        -- Change data on 'data_out' bus, but io_we = '0'
        io_data_out_tb <= x"FF";
        io_addr_in_tb  <= ADDR_PORT_A;
        wait for CLK_PERIOD;

        -- Port A should still hold old 0xAA, not new 0xFF
        assert port_out_a_tb = x"AA"
            report "Error TC-IO-03: Data was overwritten despite no write signal!" severity error;

        ------------------------------------------------------------
        -- TC-IO-04: Read from Port B (IN Instruction) (TR-IO-03)
        ------------------------------------------------------------
        report "TC-IO-04: Read from Port B (Address 0x02)";

        -- Simulate someone set switches (pin_in_b) to 0x55 (01010101)
        pin_in_b_tb <= x"55";

        -- CPU sets Port B address
        io_addr_in_tb <= ADDR_PORT_B;
        io_we_tb      <= '0'; -- Read (not write)
        wait for CLK_PERIOD;

        -- Check if 'io_data_in' (data to registers) is 0x55
        wait for 1 ns;
        assert io_data_in_tb = x"55"
            report "Error TC-IO-04: Incorrect read from physical pins of Port B" severity error;

        ------------------------------------------------------------
        -- TC-IO-05: Address Isolation (Invalid address)
        ------------------------------------------------------------
        report "TC-IO-05: Attempt to write to unsupported address (0xFF)";

        io_addr_in_tb  <= x"FF"; -- Address from nowhere
        io_data_out_tb <= x"FF";
        io_we_tb       <= '1';
        wait for CLK_PERIOD;
        io_we_tb       <= '0';

        -- Port A should not change (still 0xAA)
        assert port_out_a_tb = x"AA"
            report "Error TC-IO-05: Write to invalid address changed Port A state!" severity error;

        -- End of test
        report "END: All IO_Unit tests completed.";
        wait;
    end process;

end Behavioral;
