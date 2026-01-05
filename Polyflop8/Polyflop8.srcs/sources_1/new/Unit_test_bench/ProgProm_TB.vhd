library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity progprom_tb is
    -- Testbench has no ports
end progprom_tb;

architecture Behavioral of progprom_tb is

    -- Component Declaration
    component ProgPROM
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            address  : in  STD_LOGIC_VECTOR (10 downto 0);
            data_out : out STD_LOGIC_VECTOR (15 downto 0)
        );
    end component;

    -- Test Signals
    signal clk_tb      : STD_LOGIC := '0';
    signal reset_tb    : STD_LOGIC := '0';
    signal address_tb  : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal data_out_tb : STD_LOGIC_VECTOR(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- Helper function to print Hex in VHDL-93 (replaces VHDL-2008 to_hstring)
    function to_hex_string(slv : std_logic_vector) return string is
        variable hex_len : integer := (slv'length + 3) / 4;
        variable ret_str : string(1 to hex_len);
        variable nibble  : std_logic_vector(3 downto 0);
        variable padded_slv : std_logic_vector((hex_len * 4) - 1 downto 0);
    begin
        padded_slv := (others => '0');
        padded_slv(slv'length - 1 downto 0) := slv;
        for i in 0 to hex_len - 1 loop
            nibble := padded_slv((hex_len - i) * 4 - 1 downto (hex_len - i - 1) * 4);
            case nibble is
                when "0000" => ret_str(i+1) := '0';
                when "0001" => ret_str(i+1) := '1';
                when "0010" => ret_str(i+1) := '2';
                when "0011" => ret_str(i+1) := '3';
                when "0100" => ret_str(i+1) := '4';
                when "0101" => ret_str(i+1) := '5';
                when "0110" => ret_str(i+1) := '6';
                when "0111" => ret_str(i+1) := '7';
                when "1000" => ret_str(i+1) := '8';
                when "1001" => ret_str(i+1) := '9';
                when "1010" => ret_str(i+1) := 'A';
                when "1011" => ret_str(i+1) := 'B';
                when "1100" => ret_str(i+1) := 'C';
                when "1101" => ret_str(i+1) := 'D';
                when "1110" => ret_str(i+1) := 'E';
                when "1111" => ret_str(i+1) := 'F';
                when others => ret_str(i+1) := 'X';
            end case;
        end loop;
        return "0x" & ret_str;
    end function;

begin

    -- Instantiate the Unit Under Test (UUT)
    UUT: ProgPROM port map (
        clk      => clk_tb,
        reset    => reset_tb,
        address  => address_tb,
        data_out => data_out_tb
    );

    -- Clock Generation
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
        report "Starting PolyFlop8 Program ROM Test Bench";
        reset_tb <= '1';
        wait for 20 ns;
        reset_tb <= '0';
        wait for 20 ns;

        -- TC 1.1: Fetch from address 0x000 (LDI R1, 10)
        report "Test Case 1.1: Fetch from address 0x000";
        address_tb <= std_logic_vector(to_unsigned(0, 11));
        wait for 10 ns; 
        assert data_out_tb = x"820A"
            report "TC 1.1 Failed: Expected 0x820A, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 1.2: Fetch from address 0x001 (LDI R2, 5)
        report "Test Case 1.2: Fetch from address 0x001";
        address_tb <= std_logic_vector(to_unsigned(1, 11));
        wait for 10 ns;
        assert data_out_tb = x"8405"
            report "TC 1.2 Failed: Expected 0x8405, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 1.3: Fetch from address 0x002 (ADD R1, R2)
        report "Test Case 1.3: Fetch from address 0x002";
        address_tb <= std_logic_vector(to_unsigned(2, 11));
        wait for 10 ns;
        assert data_out_tb = x"0140"
            report "TC 1.3 Failed: Expected 0x0140, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 1.4: Fetch from address 0x003 (SUB R1, R2)
        report "Test Case 1.4: Fetch from address 0x003";
        address_tb <= std_logic_vector(to_unsigned(3, 11));
        wait for 10 ns;
        assert data_out_tb = x"0940"
            report "TC 1.4 Failed: Expected 0x0940, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 1.5: Fetch from address 0x004 (JMP 0x000)
        report "Test Case 1.5: Fetch from address 0x004";
        address_tb <= std_logic_vector(to_unsigned(4, 11));
        wait for 10 ns;
        assert data_out_tb = x"C000"
            report "TC 1.5 Failed: Expected 0xC000, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 5.1: Undefined address 0x005
        report "Test Case 5.1: Undefined address 0x005";
        address_tb <= std_logic_vector(to_unsigned(5, 11));
        wait for 10 ns;
        assert data_out_tb = x"0000"
            report "TC 5.1 Failed: Expected 0x0000, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 5.3: Near max address 0x7FE
        report "Test Case 5.3: Near max address 0x7FE";
        address_tb <= std_logic_vector(to_unsigned(2046, 11));
        wait for 10 ns;
        assert data_out_tb = x"0000"
            report "TC 5.3 Failed: Expected 0x0000, got " & to_hex_string(data_out_tb)
            severity error;

        -- TC 6.2: Max address 0x7FF
        report "Test Case 6.2: Max address 0x7FF";
        address_tb <= (others => '1');
        wait for 10 ns;
        assert data_out_tb = x"0000"
            report "TC 6.2 Failed: Expected 0x0000, got " & to_hex_string(data_out_tb)
            severity error;

        -- Async Read Verification
        report "Test Case 2.2: Asynchronous read verification";
        wait until falling_edge(clk_tb);
        address_tb <= std_logic_vector(to_unsigned(0, 11));
        wait for 1 ns; 
        assert data_out_tb = x"820A"
            report "Async Read Failed: Data did not update immediately for address 0x000"
            severity error;
            
        address_tb <= std_logic_vector(to_unsigned(1, 11));
        wait for 1 ns; 
        assert data_out_tb = x"8405"
            report "Async Read Failed: Data did not update immediately for address 0x001"
            severity error;

        report "All PolyFlop8 Program ROM tests completed.";
        wait;
    end process;

end Behavioral;