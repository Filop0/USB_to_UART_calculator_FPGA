----------------------------------------------------------------------------------
-- Module Name: MATH_BLOCK
-- Project Name: USBtoUART FPGA Calculator
-- Target Devices: Digilent Cmod S7
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity MATH_BLOCK is
  Port (
    i_Clk        : in  std_logic;
    i_reg_a      : in std_logic_vector(15 downto 0);
    i_reg_b      : in std_logic_vector(15 downto 0);
    i_operator   : in std_logic_vector(1 downto 0); -- 00 dodawanie, 01 odejmowanie, 10 mnożenie 11 dzielenie
    i_data_ready : in std_logic; -- czy odebrano enter
    o_result     : out std_logic_vector(31 downto 0);
    o_result_rdy : out std_logic
    );
end MATH_BLOCK;

architecture Behavioral of MATH_BLOCK is
begin
p_MATH_BLOCK : process (i_Clk)
-- variable v_result_acc : unsigned(31 downto 0); -- mnożenie 2^16 * 2^16 daje max 32 bity zużycia
--variable cleanup : std_logic;
begin
    if rising_edge(i_Clk) then
    o_result_rdy <= '0';
        if i_data_ready  = '1' then
            if i_operator = "00" then
               -- v_result_acc := i_reg_a + i_reg_b;
               o_result <= std_logic_vector(resize(unsigned(i_reg_a) + unsigned(i_reg_b), 32));
               o_result_rdy <= '1';
            elsif i_operator = "01" then
               o_result <= std_logic_vector(resize(unsigned(i_reg_a) - unsigned(i_reg_b), 32));
               o_result_rdy <= '1';
            elsif i_operator = "10" then
               o_result <= std_logic_vector(resize(unsigned(i_reg_a) * unsigned(i_reg_b), 32)); 
               o_result_rdy <= '1';
            else -- dzielenie
               o_result <= std_logic_vector(resize(unsigned(i_reg_a) / unsigned(i_reg_b), 32));
               o_result_rdy <= '1';  
            end if;
        end if;
    end if;
end process p_MATH_BLOCK;

end Behavioral;
