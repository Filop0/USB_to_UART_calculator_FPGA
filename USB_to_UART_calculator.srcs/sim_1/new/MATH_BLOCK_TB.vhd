library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_MATH_BLOCK is
-- Testbench nie posiada portów zewnętrznych
end tb_MATH_BLOCK;

architecture Behavioral of tb_MATH_BLOCK is

    -- Deklaracja komponentu DUT (Device Under Test)
    component MATH_BLOCK is
        Port (
            i_Clk        : in  std_logic;
            i_reg_a      : in  std_logic_vector(15 downto 0);
            i_reg_b      : in  std_logic_vector(15 downto 0);
            i_operator   : in  std_logic_vector(1 downto 0);
            i_data_ready : in  std_logic;
            o_result     : out std_logic_vector(31 downto 0);
            o_result_rdy : out std_logic
        );
    end component;

    -- Parametry symulacji
    constant C_CLK_PERIOD : time := 83 ns; -- Zegar 12 MHz

    -- Sygnały sterujące i wejściowe
    signal s_Clk        : std_logic := '0';
    signal s_reg_a      : std_logic_vector(15 downto 0) := (others => '0');
    signal s_reg_b      : std_logic_vector(15 downto 0) := (others => '0');
    signal s_operator   : std_logic_vector(1 downto 0)  := (others => '0');
    signal s_data_ready : std_logic := '0';

    -- Sygnały wyjściowe z DUT
    signal s_result     : std_logic_vector(31 downto 0);
    signal s_result_rdy : std_logic;

    -- Flaga zakończenia symulacji do zatrzymania generowania zegara
    signal s_sim_done   : boolean := false;

begin

    -- Instancja testowanego modułu
    DUT : MATH_BLOCK
        port map (
            i_Clk        => s_Clk,
            i_reg_a      => s_reg_a,
            i_reg_b      => s_reg_b,
            i_operator   => s_operator,
            i_data_ready => s_data_ready,
            o_result     => s_result,
            o_result_rdy => s_result_rdy
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
    p_STIMULUS : process
        -- Procedura pomocnicza do wysyłania pojedynczego rozkazu
        procedure execute_op (
            constant a_val : in integer;
            constant b_val : in integer;
            constant op    : in std_logic_vector(1 downto 0)
        ) is
        begin
            wait until falling_edge(s_Clk);
            s_reg_a      <= std_logic_vector(to_unsigned(a_val, 16));
            s_reg_b      <= std_logic_vector(to_unsigned(b_val, 16));
            s_operator   <= op;
            s_data_ready <= '1';

            wait until falling_edge(s_Clk);
            s_data_ready <= '0';
        end procedure;

    begin
        -- Czas na ustabilizowanie sygnałów po resecie początkowym
        wait for C_CLK_PERIOD * 2;

        ------------------------------------------------------------------------
        -- Test 1: Dodawanie (i_operator = "00") -> 120 + 35 = 155
        ------------------------------------------------------------------------
        execute_op(120, 35, "00");
        wait until rising_edge(s_Clk);

        assert s_result_rdy = '1'
            report "Blad: Brak flagi o_result_rdy dla dodawania!" severity error;
        assert to_integer(unsigned(s_result)) = 155
            report "Blad dodawania: Oczekiwano 155, otrzymano " & integer'image(to_integer(unsigned(s_result)))
            severity error;

        ------------------------------------------------------------------------
        -- Test 2: Odejmowanie (i_operator = "01") -> 300 - 45 = 255
        ------------------------------------------------------------------------
        execute_op(300, 45, "01");
        wait until rising_edge(s_Clk);

        assert s_result_rdy = '1'
            report "Blad: Brak flagi o_result_rdy dla odejmowania!" severity error;
        assert to_integer(unsigned(s_result)) = 255
            report "Blad odejmowania: Oczekiwano 255, otrzymano " & integer'image(to_integer(unsigned(s_result)))
            severity error;

        ------------------------------------------------------------------------
        -- Test 3: Mnożenie (i_operator = "10") -> 1000 * 50 = 50 000
        ------------------------------------------------------------------------
        execute_op(1000, 50, "10");
        wait until rising_edge(s_Clk);

        assert s_result_rdy = '1'
            report "Blad: Brak flagi o_result_rdy dla mnozenia!" severity error;
        assert to_integer(unsigned(s_result)) = 50000
            report "Blad mnozenia: Oczekiwano 50000, otrzymano " & integer'image(to_integer(unsigned(s_result)))
            severity error;

        ------------------------------------------------------------------------
        -- Test 4: Mnożenie dużych liczb (weryfikacja zakresu 32-bit)
        -- 65535 * 65535 = 4 294 836 225 (0xFFFE0001)
        ------------------------------------------------------------------------
        execute_op(65535, 65535, "10");
        wait until rising_edge(s_Clk);

        assert s_result_rdy = '1'
            report "Blad: Brak flagi o_result_rdy dla duzego mnozenia!" severity error;
        assert s_result = X"FFFE0001"
            report "Blad duzego mnozenia: Niepoprawny wynik 32-bit!" severity error;

        ------------------------------------------------------------------------
        -- Test 5: Dzielenie (i_operator = "11") -> 1000 / 25 = 40
        ------------------------------------------------------------------------
        execute_op(1000, 25, "11");
        wait until rising_edge(s_Clk);

        assert s_result_rdy = '1'
            report "Blad: Brak flagi o_result_rdy dla dzielenia!" severity error;
        assert to_integer(unsigned(s_result)) = 40
            report "Blad dzielenia: Oczekiwano 40, otrzymano " & integer'image(to_integer(unsigned(s_result)))
            severity error;

        ------------------------------------------------------------------------
        -- Test 6: Sprawdzenie stanu bezczynności (i_data_ready = '0')
        ------------------------------------------------------------------------
        wait until falling_edge(s_Clk);
        s_data_ready <= '0';
        wait until rising_edge(s_Clk);

        assert s_result_rdy = '0'
            report "Blad: Flaga o_result_rdy powinna opasc do '0'!" severity error;

        wait for C_CLK_PERIOD * 3;

        report "Symulacja zakonczona sukcesem." severity note;
        s_sim_done <= true;
        wait;
    end process p_STIMULUS;

end Behavioral;