-- ============================================================================
-- File:        PolyFlop8-TOP.vhd (FINAL FIX)
-- Description: Top-Level for PolyFlop8 Processor
--              Fixed ALU width mismatch (3-bit CU vs 4-bit ALU)
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PolyFlop8_MCU is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        port_out_a    : out STD_LOGIC_VECTOR (7 downto 0);
        pin_in_b      : in  STD_LOGIC_VECTOR (7 downto 0)
    );
end PolyFlop8_MCU;

architecture Structural of PolyFlop8_MCU is

    -- =========================================================
    -- SYGNA?Y WEWN?TRZNE
    -- =========================================================
    
    -- PC & Instruction
    signal pc_current      : std_logic_vector(10 downto 0);
    signal rom_data        : std_logic_vector(15 downto 0);
    signal instruction     : std_logic_vector(15 downto 0);

    -- Decoder Outputs
    signal dec_opcode      : std_logic_vector(4 downto 0);
    signal dec_rd          : std_logic_vector(2 downto 0);
    signal dec_rs_imm      : std_logic_vector(7 downto 0);
    signal dec_jump_addr   : std_logic_vector(10 downto 0);

    -- Control Unit Signals
    -- [FIX] Rozdzielenie sygna?ów: 3 bity z CU, 4 bity do ALU
    signal ctrl_alu_op_3bit   : std_logic_vector(2 downto 0); -- Wyj?cie z CU
    signal ctrl_alu_sel_4bit  : std_logic_vector(3 downto 0); -- Wej?cie do ALU

    signal ctrl_rf_src_sel    : std_logic_vector(2 downto 0); 
    signal ctrl_alu_mux_sel_a : std_logic;
    signal ctrl_alu_mux_sel_b : std_logic;
    signal ctrl_mem_we        : std_logic;
    signal ctrl_io_we         : std_logic;
    signal ctrl_regfile_we    : std_logic;
    signal ctrl_pc_src        : std_logic_vector(1 downto 0);
    signal ctrl_sreg_we       : std_logic;
    
    signal ctrl_cin           : std_logic;                    
    signal ctrl_pc_en         : std_logic;                    
    signal ctrl_ir_en         : std_logic;                    
    signal ctrl_sreg_src      : std_logic;                    
    
    signal ctrl_dram_in_sel       : std_logic_vector(1 downto 0); 
    signal ctrl_dram_data_mux_sel : std_logic_vector(1 downto 0); 
    
    -- Data Paths
    signal reg_data_a      : std_logic_vector(7 downto 0);
    signal reg_data_b      : std_logic_vector(7 downto 0);
    signal r7_x_pointer    : std_logic_vector(7 downto 0);
    
    signal alu_result      : std_logic_vector(7 downto 0);
    signal alu_flags_out   : std_logic_vector(4 downto 0);
    
    signal ram_data_out    : std_logic_vector(7 downto 0);
    signal sreg_full_out   : std_logic_vector(7 downto 0);
    
    -- IO Signals
    signal io_data_in_sig  : std_logic_vector(7 downto 0);

begin

    -- [FIX] Logika dopasowania szeroko?ci ALU
    -- CU daje 3 bity, ALU chce 4. Dodajemy '0' na pocz?tku.
    ctrl_alu_sel_4bit <= '0' & ctrl_alu_op_3bit;

    -- 1. Program Counter
    U1_PC: entity work.ProgramCounter
    port map (
        clk             => clk,
        rst             => reset,
        pc_en           => ctrl_pc_en,
        pc_src          => ctrl_pc_src,
        jump_abs_11bit  => dec_jump_addr,
        alu_out         => alu_result,
        ram_data        => ram_data_out,
        pc_out          => pc_current
    );

    -- 2. ProgPROM
    U2_ROM: entity work.ProgPROM
    port map (
        clk      => clk,
        address  => pc_current,
        enable   => '1',
        data_out => rom_data
    );

    -- 3. Instruction Register
    U3_IR: entity work.InstructionReg
    port map (
        clk         => clk,
        rst         => reset,
        ir_en       => ctrl_ir_en,
        data_in     => rom_data,
        ir_data_out => instruction
    );

    -- 4. Decoder
    U4_Dec: entity work.Decoder
    port map (
        decoder_data_in => instruction,
        opcode          => dec_opcode,
        RD              => dec_rd,
        RS_IMM          => dec_rs_imm,
        Jump11bit       => dec_jump_addr
    );

    -- 5. Control Unit
    U5_CU: entity work.ControlUnit
    port map (
        clk               => clk,
        rst               => reset,
        opcode            => dec_opcode,
        sreg_in           => sreg_full_out(1),
        
        -- Wyj?cia steruj?ce
        alu_mux_sel_b     => ctrl_alu_mux_sel_b,
        alu_mux_sel_a     => ctrl_alu_mux_sel_a,
        
        -- [FIX] Pod??czenie do sygna?u 3-bitowego
        alu_op            => ctrl_alu_op_3bit,        
        
        cin_on            => ctrl_cin,
        dram_in_sel       => ctrl_dram_in_sel,
        mem_we            => ctrl_mem_we,
        dram_data_mux_sel => ctrl_dram_data_mux_sel,
        sreg_we           => ctrl_sreg_we,
        sreg_data_in_sel  => ctrl_sreg_src,
        pc_src            => ctrl_pc_src,
        pc_en             => ctrl_pc_en,
        ir_en             => ctrl_ir_en,
        regfile_we        => ctrl_regfile_we,
        reg_file_mux_sel  => ctrl_rf_src_sel,
        io_we             => ctrl_io_we
    );

    -- 6. Register File
    U7_RegFile: entity work.RegFile
    port map (
        clk          => clk,
        reset        => reset,
        we           => ctrl_regfile_we,
        addr_a       => dec_rd,
        addr_b       => dec_rs_imm,
        addr_w       => dec_rd,
        rf_src_sel   => ctrl_rf_src_sel,
        alu_out      => alu_result,
        ram_data     => ram_data_out,
        rs_imm_in    => dec_rs_imm,
        io_data_in   => io_data_in_sig,
        sreg_data    => sreg_full_out,
        data_a       => reg_data_a,
        data_b       => reg_data_b,
        data_r7x     => r7_x_pointer
    );

    -- 7. ALU
    U8_ALU: entity work.ALU
    port map (
        pc_data        => pc_current(7 downto 0), 
        regfile_data_a => reg_data_a,
        rs_imm_in      => dec_rs_imm,
        regfile_data_b => reg_data_b,
        alu_mux_sel_a  => ctrl_alu_mux_sel_a,
        alu_mux_sel_b  => ctrl_alu_mux_sel_b,
        
        -- [FIX] Pod??czenie do sygna?u 4-bitowego (uzupe?nionego zerem)
        alu_sel        => ctrl_alu_sel_4bit,
        
        cin            => ctrl_cin,
        result         => alu_result,
        flags          => alu_flags_out
    );

    -- 8. Status Register
    U6_StatusReg: entity work.StatusReg 
    port map (
        clk            => clk,
        rst            => reset,
        sreg_we        => ctrl_sreg_we,
        sreg_src       => ctrl_sreg_src,
        alu_flags      => alu_flags_out,
        regfile_data_b => reg_data_b,
        sreg_out       => sreg_full_out
    );

    -- 9. Data RAM
    U9_RAM: entity work.DataRAM
    port map (
        clk            => clk,
        mem_we         => ctrl_mem_we,
        mem_addr_sel   => ctrl_dram_in_sel,
        mem_data_sel   => ctrl_dram_data_mux_sel,
        regfile_data_b => reg_data_b,
        alu_out        => alu_result,
        pc_data        => pc_current(7 downto 0),
        data_reg7x     => r7_x_pointer,
        regfile_data_a => reg_data_a,
        rs_imm_data    => dec_rs_imm,
        ram_data_out   => ram_data_out
    );

    -- 10. IO Unit
    U10_IO: entity work.IO_Unit
    port map (
        clk         => clk,
        reset       => reset,
        io_we       => ctrl_io_we,
        io_addr_in  => dec_rs_imm,
        io_data_out => reg_data_a,
        pin_in_b    => pin_in_b,
        io_data_in  => io_data_in_sig,
        port_out_a  => port_out_a
    );

end Structural;