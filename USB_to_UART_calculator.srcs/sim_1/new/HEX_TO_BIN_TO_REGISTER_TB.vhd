library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity tb_HEX_TO_BIN_TO_REGISTER is
end tb_HEX_TO_BIN_TO_REGISTER;

architecture sim of tb_HEX_TO_BIN_TO_REGISTER is

  -- Zegar 12 MHz (okres 83.333 ns)
  constant c_CLK_PERIOD : time := 83.333 ns;

  -- Sygnały wejściowe do modułu
  signal r_Clk     : std_logic := '0';
  signal r_RX_DV   : std_logic := '0';
  signal r_RX_Byte : std_logic_vector(7 downto 0) := (others => '0');

  -- Sygnały wyjściowe z modułu
  signal w_reg_a          : std_logic_vector(15 downto 0);
  signal w_reg_b          : std_logic_vector(15 downto 0);
  signal w_operator       : std_logic_vector(1 downto 0);
  signal w_data_ready     : std_logic;
  signal w_reg_a_overflow : std_logic;
  signal w_reg_b_overflow : std_logic;

  -- Procedura wystawiająca bajt oraz impuls i_RX_DV = '1' dokładnie na 2 takty zegara
  procedure SEND_BYTE_2CLK (
    constant c_byte : in  std_logic_vector(7 downto 0);
    signal   s_clk  : in  std_logic;
    signal   s_dv   : out std_logic;
    signal   s_data : out std_logic_vector(7 downto 0)
  ) is
  begin
--    wait until rising_edge(s_clk);
    s_data <= c_byte;
    s_dv   <= '1';
    
    -- Utrzymanie stanu wysokiego i_RX_DV przez 2 takty zegara
    wait until rising_edge(s_clk);
    
    s_dv   <= '0';
    -- Odstęp 5 taktów zegara przed kolejnym znakiem
    wait for c_CLK_PERIOD * 1;
  end procedure;

begin

  -- Podpięcie Twojego modułu (Unit Under Test)
  UUT : entity work.HEX_TO_BIN_TO_REGISTER
    port map (
      i_Clk            => r_Clk,
      i_RX_DV          => r_RX_DV,
      i_RX_Byte        => r_RX_Byte,
      o_reg_a          => w_reg_a,
      o_reg_b          => w_reg_b,
      o_operator       => w_operator,
      o_data_ready     => w_data_ready,
      o_reg_a_overflow => w_reg_a_overflow,
      o_reg_b_overflow => w_reg_b_overflow
    );

  -- Generator zegara 12 MHz
  r_Clk <= not r_Clk after c_CLK_PERIOD / 2;

  -- Główny proces wymuszający dane testowe
  p_TEST : process
  begin
    --wait for c_CLK_PERIOD * 5;

    --------------------------------------------------------------------------
    -- TEST 1: Działanie na pojedynczych cyfrach: 7 + 3
    -- Sekwencja: '7' -> Enter (0x0A) -> '+' -> Enter (0x0A) -> '3' -> Enter (0x0A)
    --------------------------------------------------------------------------
    SEND_BYTE_2CLK(X"37", r_Clk, r_RX_DV, r_RX_Byte); -- '7'
    SEND_BYTE_2CLK(X"0A", r_Clk, r_RX_DV, r_RX_Byte); -- Enter

    SEND_BYTE_2CLK(X"2B", r_Clk, r_RX_DV, r_RX_Byte); -- '+' (kod "00")
    SEND_BYTE_2CLK(X"0A", r_Clk, r_RX_DV, r_RX_Byte); -- Enter

    SEND_BYTE_2CLK(X"33", r_Clk, r_RX_DV, r_RX_Byte); -- '3'
    SEND_BYTE_2CLK(X"0A", r_Clk, r_RX_DV, r_RX_Byte); -- Enter

    -- Czas na przejście przez s_Cleanup i powrót do s_Idle
    --wait for c_CLK_PERIOD * 10;

    --------------------------------------------------------------------------
    -- TEST 2: Działanie wielocyfrowe: 12 * 4
    -- Sekwencja: '1' -> '2' -> Enter -> '*' -> Enter -> '4' -> Enter
    --------------------------------------------------------------------------
    SEND_BYTE_2CLK(X"31", r_Clk, r_RX_DV, r_RX_Byte); -- '1'
    SEND_BYTE_2CLK(X"32", r_Clk, r_RX_DV, r_RX_Byte); -- '2'
    SEND_BYTE_2CLK(X"0A", r_Clk, r_RX_DV, r_RX_Byte); -- Enter

    SEND_BYTE_2CLK(X"2A", r_Clk, r_RX_DV, r_RX_Byte); -- '*' (kod "10")
    SEND_BYTE_2CLK(X"0A", r_Clk, r_RX_DV, r_RX_Byte); -- Enter

    SEND_BYTE_2CLK(X"34", r_Clk, r_RX_DV, r_RX_Byte); -- '4'
    SEND_BYTE_2CLK(X"0A", r_Clk, r_RX_DV, r_RX_Byte); -- Enter

    wait for c_CLK_PERIOD * 10;

    -- Zatrzymanie procesu na końcu (bez wywoływania błędu $finish)
    wait;
  end process p_TEST;

end sim;