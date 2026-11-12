----------------------------------------------------------------------------------
-- Module Name: HEX_TO_BIN_TO_REGISTER
-- Project Name: USBtoUART FPGA Calculator
-- Target Devices: Digilent Cmod S7
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity HEX_TO_BIN_TO_REGISTER is
  port (
    i_Clk        : in  std_logic;
    i_RX_DV      : in std_logic;
    i_RX_Byte    : in std_logic_vector(7 downto 0);
    o_reg_a      : out std_logic_vector(15 downto 0);
    o_reg_b      : out std_logic_vector(15 downto 0);
    o_operator   : out std_logic_vector(1 downto 0); -- implementujemy 4 operacje 00 dodawanie, 01 odejmowanie, 10 mnożenie 11 dzielenie
    o_data_ready : out std_logic; -- czy odebrano enter
    o_reg_a_overflow   : out std_logic;
    o_reg_b_overflow   : out std_logic
    );
end HEX_TO_BIN_TO_REGISTER;

architecture Behavioral of HEX_TO_BIN_TO_REGISTER is
type t_SM_Main_Reg is (s_Idle, s_Reg_A, s_Operation,
                     s_Reg_B, s_Cleanup);
  signal r_SM_Main_Reg : t_SM_Main_Reg := s_Idle;
   -- Czy wpisano już chociaż jedną cyfrę?
  signal r_has_digit : std_logic := '0';
  signal r_acc_a       : unsigned(15 downto 0) := (others => '0');
  signal r_acc_b       : unsigned(15 downto 0) := (others => '0');
  signal r_a_ovf       : std_logic := '0';
  signal r_b_ovf       : std_logic := '0';
begin
 p_HEX_TO_BIN_TO_REGISTER : process (i_Clk)
    variable v_digit    : unsigned(3 downto 0);
    variable v_next_acc : unsigned(19 downto 0);
  begin
    if rising_edge(i_Clk) then
        case r_SM_Main_Reg is
            when s_Idle =>
                o_data_ready <= '0';
              if i_RX_DV = '1' then       -- Bajt oczekuje na szynie na zapisanie do rejestru
                  if (unsigned(i_RX_Byte) >= X"30" and unsigned(i_RX_Byte) <= X"39") then
                    v_digit       := unsigned(i_RX_Byte(3 downto 0));
                    r_acc_a       <= resize(v_digit, 16); -- Zapisz pierwszą cyfrę!
                    r_acc_b       <= (others => '0');
                    r_has_digit <= '1';
                  end if;
                    r_a_ovf       <= '0';
                    r_b_ovf       <= '0';
                    o_operator    <= (others => '0');
                    o_reg_a_overflow  <= '0';
                    o_reg_b_overflow  <= '0';
                    r_SM_Main_Reg <= s_Reg_A;
                    
                  else
                    r_SM_Main_Reg <= s_Idle;
                  end if;
              
            when s_Reg_A =>
                if i_RX_DV = '1' then
                    if (unsigned(i_RX_Byte) >= X"30" and unsigned(i_RX_Byte) <= X"39") then
                        v_digit := unsigned(i_rx_byte(3 downto 0));
                        v_next_acc := ("0" & r_acc_a & "000") + ("000" & r_acc_a & "0") + v_digit;
                        if v_next_acc > 65535 then
                            r_a_ovf <= '1';
                            r_acc_a <= (others => '1'); -- Nasycenie na 65535
                        else
                            r_acc_a <= v_next_acc(15 downto 0);
                        end if;
                        r_has_digit <= '1';
                        
                    elsif (i_RX_Byte = X"0A") then -- wcisnieto ENTER
                        if r_has_digit = '1' then
                            o_reg_a <= std_logic_vector(r_acc_a);
                            r_has_digit <= '0';
                            r_SM_Main_Reg <= s_Operation;
                        end if;
                    else
                        null;     
                    end if;
                end if;
                
            when s_Operation => 
                if i_RX_DV = '1' then
                    if (i_RX_Byte = X"2B") then -- dodawanie
                        o_operator <= "00";
                        r_has_digit <= '1';
                    elsif (i_RX_Byte = X"2D") then -- odejmowanie
                        o_operator <= "01";
                        r_has_digit <= '1';
                    elsif (i_RX_Byte = X"2A") then -- mnożenie
                        o_operator <= "10";
                        r_has_digit <= '1';
                    elsif (i_RX_Byte = X"2F") then -- dzielenie
                        o_operator <= "11";
                        r_has_digit <= '1';

                    elsif (i_RX_Byte = X"0A") then -- wcisnieto ENTER
                        if r_has_digit = '1' then
                            r_has_digit <= '0';
                            r_SM_Main_Reg <= s_Reg_B;
                        end if;
                    end if;
                end if;
                        
            when s_Reg_B =>
                if i_RX_DV = '1' then
                    if (unsigned(i_RX_Byte) >= X"30" and unsigned(i_RX_Byte) <= X"39") then
                            v_digit := unsigned(i_rx_byte(3 downto 0));
                            v_next_acc := ("0" & r_acc_b & "000") + ("000" & r_acc_b & "0") + v_digit;
                            if v_next_acc > 65535 then
                                r_b_ovf <= '1';
                                r_acc_b <= (others => '1'); -- Nasycenie na 65535
                            else
                                r_acc_b <= v_next_acc(15 downto 0);
                            end if;
    
                            r_has_digit <= '1';
                            
                        elsif (i_RX_Byte = X"0A") then -- wcisnieto ENTER
                            if r_has_digit = '1' then 
                                o_reg_b <= std_logic_vector(r_acc_b);
                                r_has_digit <= '0';
                                r_SM_Main_Reg <= s_Cleanup;
                                o_data_ready <= '1';
                            end if;
                        else
                            null;    
                        end if;
                end if;
            
            
            when s_Cleanup =>
                r_SM_Main_Reg <= s_Idle;
                o_reg_a_overflow <= r_a_ovf;
                o_reg_b_overflow <= r_b_ovf;
                o_data_ready     <= '0';
                r_acc_a       <= (others => '0');

                
            when others =>
                r_SM_Main_Reg <= s_Idle;
                
        end case;
    end if;
    
end process p_HEX_TO_BIN_TO_REGISTER;

end Behavioral;
