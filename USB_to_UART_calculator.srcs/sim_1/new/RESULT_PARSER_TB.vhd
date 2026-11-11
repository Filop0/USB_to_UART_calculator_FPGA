library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RESULT_PARESER_TB is
end RESULT_PARESER_TB;

architecture Behavioral of RESULT_PARESER_TB is

    -- Deklaracja komponentu DUT (Device Under Test)
    component RESULT_PARSER is
         Port (
            i_Clk              : in std_logic;
            i_reg_a_overflow   : in std_logic;
            i_reg_b_overflow   : in std_logic;
            i_result_rdy       : in std_logic;
            i_TX_Active        : in std_logic; -- sprawdzam czy UART nie nadaje w tej chwili
            i_result           : in std_logic_vector(31 downto 0);
            o_TX_DV            : out std_logic;
            o_TX_Byte          : out std_logic_vector(7 downto 0)
            );
    end component;

    -- Parametry symulacji
    constant C_CLK_PERIOD : time := 83 ns; -- Zegar 12 MHz

    -- Sygnały sterujące i wejściowe
    signal s_Clk        : std_logic := '0';
    signal s_reg_a_overflow : std_logic := '0';
    signal s_reg_b_overflow : std_logic := '0';
    signal s_TX_Active  : std_logic := '0';
    signal s_result_rdy : std_logic := '0';
    signal s_result     : std_logic_vector(31 downto 0)  := (others => '0');


    -- Sygnały wyjściowe z DUT
    signal s_TX_DV   : std_logic;
    signal s_TX_Byte : std_logic_vector(7 downto 0) := (others => '0');

    -- Flaga zakończenia symulacji do zatrzymania generowania zegara
    signal s_sim_done   : boolean := false;

begin

    -- Instancja testowanego modułu
    DUT : RESULT_PARSER
        port map (
            i_Clk => s_Clk,
            i_reg_a_overflow => s_reg_a_overflow,
            i_reg_b_overflow => s_reg_b_overflow,
            i_TX_Active => s_TX_Active,
            i_result_rdy => s_result_rdy,
            i_result => s_result,
            o_TX_DV => s_TX_DV,
            o_TX_Byte => s_TX_Byte
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
        -- Procedura pomocnicza do wysyłania pojedynczego rozkazu
        procedure execute_op (
            constant result    : in integer
        ) is
        begin
            wait until falling_edge(s_Clk);
            s_result <= std_logic_vector(to_unsigned(result, 32));
            s_result_rdy <= '1';
            wait until falling_edge(s_Clk);
            s_result_rdy <= '0';
            --s_result <= std_logic_vector(to_unsigned(0, 32));
        end procedure;

    begin
        -- Czas na ustabilizowanie sygnałów po resecie początkowym
        wait for C_CLK_PERIOD * 2;
        s_TX_Active <= '0';
        ------------------------------------------------------------------------
        -- Test 1: 32767
        ------------------------------------------------------------------------
        execute_op(32767);
        wait for C_CLK_PERIOD * 30;

        ------------------------------------------------------------------------
        -- Test 2: 200
        ------------------------------------------------------------------------
        execute_op(200);
        wait for C_CLK_PERIOD * 30;

        ------------------------------------------------------------------------
        -- Test 3: UART jest zajęty
        ------------------------------------------------------------------------
        s_TX_Active <= '1';
        
        execute_op(111);
        wait for C_CLK_PERIOD * 30;
        
        s_TX_Active <= '0'; -- Zwalniamy UART
        wait for C_CLK_PERIOD * 10;
        
        report "Symulacja zakonczona sukcesem." severity note;
        s_sim_done <= true;
        wait;
    end process p_TEST;

end Behavioral; 