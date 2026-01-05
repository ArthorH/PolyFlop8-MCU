library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_tb is
-- Testbench has no ports
end ALU_tb;

architecture Behavioral of ALU_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component ALU
        Port (
            pc_data        : in  STD_LOGIC_VECTOR (7 downto 0);
            regfile_data_a : in  STD_LOGIC_VECTOR (7 downto 0);
            rs_imm_in      : in  STD_LOGIC_VECTOR (7 downto 0);
            regfile_data_b : in  STD_LOGIC_VECTOR (7 downto 0);
            alu_mux_sel_a  : in  STD_LOGIC;
            alu_mux_sel_b  : in  STD_LOGIC;
            alu_sel        : in  STD_LOGIC_VECTOR (3 downto 0);
            cin            : in  STD_LOGIC;
            result         : out STD_LOGIC_VECTOR (7 downto 0);
            flags          : out STD_LOGIC_VECTOR (4 downto 0)
        );
    end component;

    -- Signals to connect to UUT
    signal pc_data        : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal regfile_data_a : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal rs_imm_in      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal regfile_data_b : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal alu_mux_sel_a  : STD_LOGIC := '0';
    signal alu_mux_sel_b  : STD_LOGIC := '0';
    signal alu_sel        : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    signal cin            : STD_LOGIC := '0';
    
    signal result         : STD_LOGIC_VECTOR (7 downto 0);
    signal flags          : STD_LOGIC_VECTOR (4 downto 0);

    -- Flag Aliases for readability (Flags: H, V, N, C, Z)
    alias H_flag : std_logic is flags(4);
    alias V_flag : std_logic is flags(3);
    alias N_flag : std_logic is flags(2);
    alias C_flag : std_logic is flags(1);
    alias Z_flag : std_logic is flags(0);

    -- Operation Constants (Based on Block Spec Table 2.3)
    constant OP_ADD : std_logic_vector(3 downto 0) := "0000";
    constant OP_ADC : std_logic_vector(3 downto 0) := "0001";
    constant OP_SUB : std_logic_vector(3 downto 0) := "0010";
    constant OP_SBC : std_logic_vector(3 downto 0) := "0011";
    constant OP_AND : std_logic_vector(3 downto 0) := "0100";
    constant OP_OR  : std_logic_vector(3 downto 0) := "0101";
    constant OP_XOR : std_logic_vector(3 downto 0) := "0110";
    constant OP_MOV : std_logic_vector(3 downto 0) := "0111"; -- Pass B
    constant OP_LDI : std_logic_vector(3 downto 0) := "1000"; -- Pass A
    constant OP_COM : std_logic_vector(3 downto 0) := "1001"; -- 1's Comp
    constant OP_NEG : std_logic_vector(3 downto 0) := "1010"; -- 2's Comp

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: ALU PORT MAP (
        pc_data => pc_data,
        regfile_data_a => regfile_data_a,
        rs_imm_in => rs_imm_in,
        regfile_data_b => regfile_data_b,
        alu_mux_sel_a => alu_mux_sel_a,
        alu_mux_sel_b => alu_mux_sel_b,
        alu_sel => alu_sel,
        cin => cin,
        result => result,
        flags => flags
    );

    -- Stimulus process
    stim_proc: process
        -- Helper procedure to check results
        procedure check_alu(
            desc : string;
            exp_res : integer;
            exp_flags : std_logic_vector(4 downto 0) -- H, V, N, C, Z
        ) is
        begin
            wait for 10 ns;
            assert std_match(result, std_logic_vector(to_unsigned(exp_res, 8)))
                report desc & " - Result Mismatch! Expected: " & integer'image(exp_res) & 
                       " Got: " & integer'image(to_integer(unsigned(result)))
                severity error;
                
            -- Check flags individually with 'X' support for "don't care"
            if (exp_flags(4) /= 'X') then
                assert H_flag = exp_flags(4) report desc & " - H Flag Error" severity error;
            end if;
            if (exp_flags(3) /= 'X') then
                assert V_flag = exp_flags(3) report desc & " - V Flag Error" severity error;
            end if;
            if (exp_flags(2) /= 'X') then
                assert N_flag = exp_flags(2) report desc & " - N Flag Error" severity error;
            end if;
            if (exp_flags(1) /= 'X') then
                assert C_flag = exp_flags(1) report desc & " - C Flag Error" severity error;
            end if;
            if (exp_flags(0) /= 'X') then
                assert Z_flag = exp_flags(0) report desc & " - Z Flag Error" severity error;
            end if;
        end procedure;

    begin
        report "Starting ALU Verification...";

        -- =========================================================
        -- 1. Test Multiplexer Inputs (TR-ALU-03, TR-ALU-04)
        -- =========================================================
        report "Testing Multiplexers...";
        
        -- Set distinct values on all inputs
        regfile_data_a <= x"10"; -- 16
        pc_data        <= x"20"; -- 32
        regfile_data_b <= x"01"; -- 1
        rs_imm_in      <= x"02"; -- 2

        -- Case 1: Select RegA + RegB (16 + 1 = 17)
        alu_mux_sel_a <= '0';
        alu_mux_sel_b <= '0';
        alu_sel <= OP_ADD;
        check_alu("MUX: RegA + RegB", 17, "00000");

        -- Case 2: Select PC + RegB (32 + 1 = 33)
        alu_mux_sel_a <= '1'; -- Select PC
        alu_mux_sel_b <= '0';
        check_alu("MUX: PC + RegB", 33, "00000");

        -- Case 3: Select RegA + Imm (16 + 2 = 18)
        alu_mux_sel_a <= '0';
        alu_mux_sel_b <= '1'; -- Select Imm
        check_alu("MUX: RegA + Imm", 18, "00000");

        -- Reset Muxes to default (RegA, RegB) for Arithmetic tests
        alu_mux_sel_a <= '0'; 
        alu_mux_sel_b <= '0';

        -- =========================================================
        -- 2. Arithmetic Operations (TR-ALU-01)
        -- =========================================================
        report "Testing Arithmetic...";

        -- ADD: 10 + 20 = 30
        regfile_data_a <= x"0A";
        regfile_data_b <= x"14";
        alu_sel <= OP_ADD;
        check_alu("ADD: Basic", 30, "00000");

        -- ADD: Overflow Check (100 + 100 = 200 -> -56 signed)
        -- 0x64 + 0x64 = 0xC8. 
        -- H=0, V=1 (Pos+Pos=Neg), N=1 (Result negative), C=0, Z=0
        regfile_data_a <= x"64"; 
        regfile_data_b <= x"64";
        check_alu("ADD: Signed Overflow", 200, "01100");

        -- ADD: Half Carry Check (0x0F + 0x01 = 0x10)
        -- Bit 3 overflows to Bit 4 -> H=1
        regfile_data_a <= x"0F";
        regfile_data_b <= x"01";
        check_alu("ADD: Half Carry", 16, "10000");

        -- SUB: 20 - 10 = 10
        regfile_data_a <= x"14";
        regfile_data_b <= x"0A";
        alu_sel <= OP_SUB;
        check_alu("SUB: Basic", 10, "X0000");

        -- SUB: Zero Flag (55 - 55 = 0)
        regfile_data_a <= x"37";
        regfile_data_b <= x"37";
        check_alu("SUB: Zero Result", 0, "X0001");

        -- ADC: 10 + 10 + Carry(1) = 21
        cin <= '1';
        regfile_data_a <= x"0A";
        regfile_data_b <= x"0A";
        alu_sel <= OP_ADC;
        check_alu("ADC: With Carry", 21, "00000");
        cin <= '0';

        -- =========================================================
        -- 3. Logic Operations
        -- =========================================================
        report "Testing Logic...";

        -- AND: 0x0F AND 0x55 (00001111 AND 01010101 = 00000101 -> 0x05)
        regfile_data_a <= x"0F";
        regfile_data_b <= x"55";
        alu_sel <= OP_AND;
        check_alu("AND", 5, "XX0XX");

        -- OR: 0x0F OR 0x55 (00001111 OR 01010101 = 01011111 -> 0x5F)
        check_alu("OR", 95, "XX0XX"); -- Note: You must switch alu_sel, added below
        alu_sel <= OP_OR;
        check_alu("OR Exec", 95, "XX0XX");

        -- XOR: 0x55 XOR 0xFF = 0xAA (10101010)
        -- Result is negative (MSB=1), so N=1
        regfile_data_a <= x"55";
        regfile_data_b <= x"FF";
        alu_sel <= OP_XOR;
        check_alu("XOR", 170, "XX1X0");

        -- =========================================================
        -- 4. Pass-Through Operations (MOV, LDI)
        -- =========================================================
        report "Testing Pass-Through...";

        regfile_data_a <= x"AA";
        regfile_data_b <= x"BB";

        -- MOV (Pass B)
        alu_sel <= OP_MOV;
        check_alu("MOV (Pass B)", 187, "XXXXX"); -- Expect 0xBB

        -- LDI (Pass A)
        alu_sel <= OP_LDI;
        check_alu("LDI (Pass A)", 170, "XXXXX"); -- Expect 0xAA

        -- =========================================================
        -- 5. Unary Operations (COM, NEG) (TR-ALU-05)
        -- =========================================================
        report "Testing Unary...";

        -- COM (One's Complement): NOT 00000000 = 11111111 (0xFF)
        -- Flags: C=1, Z, N logic applies
        regfile_data_a <= x"00";
        alu_sel <= OP_COM;
        check_alu("COM: Zero", 255, "XX110"); 

        -- NEG (Two's Complement): 0 - 1 = -1 (0xFF)
        -- 0 - 0x01 = 0xFF. 
        -- Flags: C=1 (Borrow), V=0, N=1, Z=0
        regfile_data_a <= x"01";
        alu_sel <= OP_NEG;
        check_alu("NEG: -1", 255, "X0110");

        -- NEG: Overflow (NEG -128)
        -- Negating 0x80 (-128) results in 0x80 (-128) -> Overflow!
        regfile_data_a <= x"80";
        check_alu("NEG: Overflow", 128, "X1110");

        -- NEG: Zero (0 - 0 = 0)
        -- C should be 0, Z should be 1
        regfile_data_a <= x"00";
        check_alu("NEG: Zero", 0, "X0001");

        report "ALU Verification Complete.";
        wait;
    end process;

end Behavioral;