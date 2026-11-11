----------------------------------------------------------------------------------
-- Module Name: MATH_BLOCK
-- Project Name: USBtoUART FPGA Calculator
-- Target Devices: Digilent Cmod S7
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity RESULT_PARSER is
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
end RESULT_PARSER;

architecture Behavioral of RESULT_PARSER is
    
begin

 p_RESULT_PARSER : process (i_Clk)
    variable v_single_digit_acc : unsigned(3 downto 0);
    variable decoder_raw_buffer : integer range 0 to 32767 := 0; -- narazie tylko dodatnie
    variable decoder_raw_buffer2 : integer range 0 to 32767 := 0; -- narazie tylko dodatnie
    type digits is array (0 to 4) of integer range -1 to 9 ;
    variable digits_buffer : digits := (others => -1);
    variable digits_length : integer range 1 to 5 := 1;
    variable char_buffer   : integer range 0 to 9;
    variable char_pending  : boolean := false;
    variable negative      : boolean := false;
    variable cooldown      : boolean := false;
    variable factor : integer range 0 to 10000 := 0;
    variable counter : integer range 0 to 5 := 0;

    begin
    if rising_edge (i_Clk) then
    
        buf_decoder : if i_result_rdy = '1' then
    
            decoder_raw_buffer := to_integer(unsigned(i_result));
            decoder_raw_buffer2 := to_integer(unsigned(i_result));
            negative := false;
            digits_buffer := (others => 0);
            digits_length := 1;
            factor := 10000;
            counter := 5;
    
            if decoder_raw_buffer < 0 then -- narazie nie dotyczy
                negative           := true;
                decoder_raw_buffer := decoder_raw_buffer * (-1);
            end if;
        end if buf_decoder;
            
        if counter > 0 then 
              --   32767 3 digits_length = 5. 2 digits_length = 4. 7 d_l = 3. 6 d_l = 2. 7 d_l = 1
            if (decoder_raw_buffer mod factor) /= decoder_raw_buffer then
                digits_buffer(counter-1)   := decoder_raw_buffer / factor;
                decoder_raw_buffer := decoder_raw_buffer - (digits_buffer(counter-1) * factor);
                
                if digits_length = 1 then -- wg mnie tutaj jest błąd 
                    digits_length := counter;
                end if;
            end if;
            if counter = 1 then 
                 char_pending := true; 
            end if;
    
            factor := factor / 10;
            counter := counter - 1;

        end if; 
                
  
            do_send_char : if ((i_TX_Active = '0') and char_pending) then -- and (decoder_raw_buffer2 /= 0)
                if cooldown then
                    o_TX_DV <= '0';
                    cooldown        := false;
                else
    
                    send_type : if negative then -- narazie nigdy nie wejdzie
                        o_TX_Byte      <= X"2D";
                        o_TX_DV <= '1';
                        negative        := false;
                        cooldown        := true;
    
                    elsif digits_length > 0 then -- 
                        char_buffer := digits_buffer(digits_length - 1);
                        encode : case (char_buffer) is
    
                            when 0 => o_TX_Byte <= X"30";
                            when 1 => o_TX_Byte <= X"31";
                            when 2 => o_TX_Byte <= X"32";
                            when 3 => o_TX_Byte <= X"33";
                            when 4 => o_TX_Byte <= X"34";
                            when 5 => o_TX_Byte <= X"35";
                            when 6 => o_TX_Byte <= X"36";
                            when 7 => o_TX_Byte <= X"37";
                            when 8 => o_TX_Byte <= X"38";
                            when 9 => o_TX_Byte <= X"39";
                        end case encode;
                        o_TX_DV <= '1';
                        cooldown        := true;
    
                        digits_length := digits_length - 1;
    
                    else
                        o_TX_Byte      <= X"0A";
                        o_TX_DV <= '1';
                        char_pending    := false;
    
                    end if send_type;
                end if;
            else
                o_TX_DV <= '0';
                --decoder_raw_buffer := 0;
                --decoder_raw_buffer2 := 0;
            end if do_send_char;
            
        
       
    end if;
    
end process p_RESULT_PARSER;

end Behavioral;
