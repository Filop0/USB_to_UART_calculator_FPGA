library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity TOP_TB is
end TOP_TB;

architecture Behavioral of TOP_TB is
component TOP is
         Port (
                i_Clk       : in  std_logic;
                i_RX_UART_Pin : in  std_logic;
                o_TX_UART_Pin : out std_logic
            );
    end component;

    -- Parametry symulacji
    constant C_CLK_PERIOD : time := 83 ns; -- Zegar 12 MHz
    constant c_CLKS_PER_BIT : integer := 104;
     -- 1/115200:
    constant c_BIT_PERIOD : time := 8680 ns;
  
    -- Sygnały sterujące i wejściowe
    signal s_Clk        : std_logic := '0';
    signal s_RX_UART_Pin  : std_logic := '1';



    -- Sygnały wyjściowe z DUT
    signal s_TX_UART_Pin   : std_logic;

    -- Flaga zakończenia symulacji do zatrzymania generowania zegara
    signal s_sim_done   : boolean := false;

begin

    -- Instancja testowanego modułu
    DUT : TOP
        port map (
            i_Clk => s_Clk,
            i_RX_UART_Pin => s_RX_UART_Pin,
            o_TX_UART_Pin => s_TX_UART_Pin
        );

    -- Proces generacji sygnału zegarowego
    p_CLK_GEN : process
    begin
        while not s_sim_done loop
            s_Clk <= '0';
            wait for C_CLK_PERIOD / 2;
            s_Clk <= '1';
            wait for C_CLK_PERIOD / 2;
        end loop;
        wait;
    end process p_CLK_GEN;

    -- Główny proces stymulacji i weryfikacji
    p_TEST : process
        

        procedure UART_WRITE_BYTE (
            i_Data_In       : in  std_logic_vector(7 downto 0);
            signal o_Serial : out std_logic) is
          begin
        
            -- Send Start Bit
            o_Serial <= '0';
            wait for c_BIT_PERIOD;
        
            -- Send Data Byte
            for ii in 0 to 7 loop
              o_Serial <= i_Data_In(ii);
              wait for c_BIT_PERIOD;
            end loop;  -- ii
        
            -- Send Stop Bit
            o_Serial <= '1';
            wait for c_BIT_PERIOD;
          end UART_WRITE_BYTE;
          
    begin
        -- Czas na ustabilizowanie sygnałów po resecie początkowym
        wait for c_BIT_PERIOD * 2;

        ------------------------------------------------------------------------
        -- Test 1: 7 + 3 = 10
        ------------------------------------------------------------------------
        -- Send a command to the UART
        wait until rising_edge(s_Clk);
        UART_WRITE_BYTE(X"37", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"2B", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"33", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        wait until rising_edge(s_Clk);
        wait for c_BIT_PERIOD * 100;
        
        ------------------------------------------------------------------------
        -- Test 2: 7 - 3 = 4 
        ------------------------------------------------------------------------
        -- Send a command to the UART
        wait until rising_edge(s_Clk);
        UART_WRITE_BYTE(X"37", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"2D", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"33", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        wait until rising_edge(s_Clk);
        wait for c_BIT_PERIOD * 100;
        
        ------------------------------------------------------------------------
        -- Test 3: 7 * 3 = 21 
        ------------------------------------------------------------------------
        -- Send a command to the UART
        wait until rising_edge(s_Clk);
        UART_WRITE_BYTE(X"37", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"2A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"33", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        wait until rising_edge(s_Clk);
        wait for c_BIT_PERIOD * 100;
        
        ------------------------------------------------------------------------
        -- Test 4: 21 / 3 = 7 
        ------------------------------------------------------------------------
        -- Send a command to the UART
        wait until rising_edge(s_Clk);
        UART_WRITE_BYTE(X"32", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"31", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"2F", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"33", s_RX_UART_Pin);
        UART_WRITE_BYTE(X"0A", s_RX_UART_Pin);
        wait until rising_edge(s_Clk);
        wait for c_BIT_PERIOD * 100;
        
        report "Symulacja zakonczona" severity note;
        s_sim_done <= true;
        wait;
    end process p_TEST;

end Behavioral; 
