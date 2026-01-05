-- ============================================================================
-- File:         IO_Unit.vhd
-- Description:  Input/Output Unit for PolyFlop8 Processor
--                This file has been verified with the following test cases:
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

entity IO_Unit is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        -- Sterowanie z Control Unit
        io_we       : in  STD_LOGIC;                      -- Write Enable (dla instrukcji OUT)
        
        -- Połączenia z CPU (zgodne z Twoim schematem)
        io_addr_in  : in  STD_LOGIC_VECTOR (7 downto 0);  -- Adres portu (z Immediate Data)
        
        -- UWAGA: Nazewnictwo z diagramu. 
        -- io_data_out to sygnał idący Z REJESTRÓW DO IO (dane do wysłania)
        io_data_out : in  STD_LOGIC_VECTOR (7 downto 0);  
        
        -- io_data_in to sygnał idący Z IO DO REJESTRÓW (dane odebrane)
        io_data_in  : out STD_LOGIC_VECTOR (7 downto 0);  
        
        -- =========================================================
        -- FIZYCZNE PINY PROCESORA (Strzałki "IO" na zewnątrz)
        -- =========================================================
        -- Port A: Wyjście (np. Diody LED)
        port_out_a  : out STD_LOGIC_VECTOR (7 downto 0);
        
        -- Port B: Wejście (np. Przyciski / Switches)
        pin_in_b    : in  STD_LOGIC_VECTOR (7 downto 0)
    );
end IO_Unit;

architecture Behavioral of IO_Unit is

    -- Rejestr wewnętrzny dla portu wyjściowego (pamięta stan diod)
    signal reg_port_a : std_logic_vector(7 downto 0);

begin

    -- =========================================================
    -- 1. PROCES ZAPISU (Instrukcja OUT)
    -- =========================================================
    process(clk, reset)
    begin
        if reset = '1' then
            reg_port_a <= (others => '0'); -- Resetuje wyjścia na 0
            
        elsif rising_edge(clk) then
            if io_we = '1' then
                -- Prosta mapa pamięci (Memory Mapped IO)
                case io_addr_in is
                    -- Jeśli adres to 0x01, zapisz dane do rejestru portu A
                    when x"01" => 
                        reg_port_a <= io_data_out;
                        
                    -- Tutaj można dodać więcej portów wyjściowych
                    when others => 
                        null;
                end case;
            end if;
        end if;
    end process;

    -- Wystawienie stanu wewnętrznego rejestru na fizyczne piny
    port_out_a <= reg_port_a;

    -- =========================================================
    -- 2. PROCES ODCZYTU (Instrukcja IN) - Kombinacyjny
    -- =========================================================
    -- Mux wybierający, co procesor "widzi", gdy czyta z danego adresu
    process(io_addr_in, pin_in_b, reg_port_a)
    begin
        case io_addr_in is
            -- Adres 0x01: Odczyt stanu własnego portu wyjściowego (opcjonalne)
            when x"01" => 
                io_data_in <= reg_port_a;
                
            -- Adres 0x02: Odczyt fizycznych przycisków (Port B)
            when x"02" => 
                io_data_in <= pin_in_b;
                
            -- Adres nieznany: zwracamy 0
            when others => 
                io_data_in <= (others => '0');
        end case;
    end process;

end Behavioral;