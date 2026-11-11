----------------------------------------------------------------------------------
-- TOP Module parsing all submodules
-- Project Name: USBtoUART FPGA Calculator
-- Target Devices: Digilent Cmod S7
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP is
Port (
    i_Clk       : in  std_logic;
    i_RX_UART_Pin : in  std_logic;
    o_TX_UART_Pin : out std_logic
    );
end TOP;

architecture Structural of TOP is
signal s_rx_byte : std_logic_vector(7 downto 0);
signal s_rx_dv : std_logic;
signal s_reg_a : std_logic_vector(15 downto 0);
signal s_reg_b : std_logic_vector(15 downto 0);
signal s_operator : std_logic_vector(1 downto 0);
signal s_data_ready : std_logic;
signal s_result : std_logic_vector(31 downto 0);
signal s_result_rdy : std_logic;
signal s_tx_active : std_logic;
signal s_tx_byte : std_logic_vector(7 downto 0);
signal s_tx_dv : std_logic;
signal s_reg_a_overflow : std_logic;
signal s_reg_b_overflow : std_logic;
signal s_tx_done : std_logic;
begin
Inst_UART_RX : entity work.UART_RX
        port map (
            i_Clk       => i_Clk,
            i_RX_Serial => i_RX_UART_Pin,
            o_RX_DV     => s_rx_dv,
            o_RX_Byte   => s_rx_byte
        );

Inst_HEX_TO_BIN : entity work.HEX_TO_BIN_TO_REGISTER
        port map (
            i_Clk       => i_Clk,
            i_RX_DV     => s_rx_dv,
            i_RX_Byte   => s_rx_byte,
            o_reg_a     => s_reg_a,
            o_reg_b     => s_reg_b,
            o_operator  => s_operator,
            o_data_ready => s_data_ready,
            o_reg_a_overflow => s_reg_a_overflow,
            o_reg_b_overflow => s_reg_b_overflow
        );
        
Inst_MATH_BLOCK : entity work.MATH_BLOCK
        port map (
            i_Clk       => i_Clk,
            i_reg_a     => s_reg_a,
            i_reg_b     => s_reg_b,
            i_operator  => s_operator,
            i_data_ready => s_data_ready,
            o_result    => s_result,
            o_result_rdy => s_result_rdy
        );

Inst_RESULT_PARSER : entity work.RESULT_PARSER
        port map (
            i_Clk       => i_Clk,
            i_reg_a_overflow     => s_reg_a_overflow,
            i_reg_b_overflow     => s_reg_b_overflow,
            i_result_rdy  => s_result_rdy,
            i_TX_Active => s_tx_active,
            i_result    => s_result,
            o_TX_DV => s_tx_dv,
            o_TX_Byte => s_tx_byte
        );

Inst_UART_TX : entity work.UART_TX
        port map (
            i_Clk       => i_Clk,
            i_TX_DV     => s_tx_dv,
            i_TX_Byte     => s_tx_byte,
            o_TX_Active   => s_tx_active,
            o_TX_Serial   => o_TX_UART_Pin,
            o_TX_Done     => s_tx_done
        );

end Structural;
