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
    i_reset            : in  std_logic;
    i_TX_Active        : in std_logic; -- sprawdzam czy UART nie nadaje w tej chwili
    i_result           : in std_logic_vector(31 downto 0);
    o_wyswietlono_komunikat     : out std_logic;
    o_TX_DV            : out std_logic;
    o_TX_Byte          : out std_logic_vector(7 downto 0)
  );
end RESULT_PARSER;

architecture Behavioral of RESULT_PARSER is
    
begin

 p_RESULT_PARSER : process (i_Clk)
    variable v_single_digit_acc : unsigned(3 downto 0);
    variable decoder_raw_buffer : integer range 0 to 2147483647 := 0;
    type digits is array (0 to 4) of integer range -1 to 9 ;
    variable digits_buffer : digits := (others => -1);
    variable digits_length : integer range 0 to 5 := 1;
    variable cooldown_cnt  : integer range 0 to 35 := 0;
    variable char_buffer   : integer range 0 to 9;
    variable char_pending  : boolean := false;
    variable negative      : boolean := false;
    variable cooldown      : boolean := false;
    variable factor : integer range 0 to 10000 := 0;
    variable counter : integer range 0 to 5 := 0;
    variable welcome_msg_counter : integer range 0 to 225 := 0;
    variable wyswietlono_komunikat : std_logic := '0';
    variable msg_cooldown_cnt  : integer range 0 to 1100 := 0;
    type rom_type is array (0 to 225) of std_logic_vector(7 downto 0);
    constant WELCOME_ROM : rom_type := (
    -- "Projekt kalkulatora na ZAMPF\n" (29 B: indeksy 0..28)
    x"50", x"72", x"6F", x"6A", x"65", x"6B", x"74", x"20", x"6B", x"61", x"6C", x"6B", x"75", x"6C", x"61", x"74", x"6F", x"72", x"61", x"20", x"6E", x"61", x"20", x"5A", x"41", x"4D", x"50", x"46", x"0A",
    
    -- "Filip Kapelanski i Hubert Kowalczyk\n" (36 B: indeksy 29..64)
    x"46", x"69", x"6C", x"69", x"70", x"20", x"4B", x"61", x"70", x"65", x"6C", x"61", x"6E", x"73", x"6B", x"69", x"20", x"69", x"20", x"48", x"75", x"62", x"65", x"72", x"74", x"20", x"4B", x"6F", x"77", x"61", x"6C", x"63", x"7A", x"79", x"6B", x"0A",
    
    -- "-----------------------------------\n" (36 B: indeksy 65..100)
    x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"2D", x"0A",
    
    -- "Konstruowanie dzialan:\n" (23 B: indeksy 101..123)
    x"4B", x"6F", x"6E", x"73", x"74", x"72", x"75", x"6F", x"77", x"61", x"6E", x"69", x"65", x"20", x"64", x"7A", x"69", x"61", x"6C", x"61", x"6E", x"3A", x"0A",
    
    -- "<liczba1>{Enter}<dzialanie>{Enter}<liczba2>{Enter}\n" (51 B: indeksy 124..174)
    x"3C", x"6C", x"69", x"63", x"7A", x"62", x"61", x"31", x"3E", x"7B", x"45", x"6E", x"74", x"65", x"72", x"7D", x"3C", x"64", x"7A", x"69", x"61", x"6C", x"61", x"6E", x"69", x"65", x"3E", x"7B", x"45", x"6E", x"74", x"65", x"72", x"7D", x"3C", x"6C", x"69", x"63", x"7A", x"62", x"61", x"32", x"3E", x"7B", x"45", x"6E", x"74", x"65", x"72", x"7D", x"0A",
    
    -- "gdzie liczba1 i 2 miesci sie w zakresie 0 do 46000\n" (47 B: indeksy 175..221)
    x"67", x"64", x"7A", x"69", x"65", x"20", x"6C", x"69", x"63", x"7A", x"62", x"61", x"31", x"20", x"69", x"20", x"32", x"20", x"6D", x"69", x"65", x"73", x"63", x"69", x"20", x"73", x"69", x"65", x"20", x"77", x"20", x"7A", x"61", x"6B", x"72", x"65", x"73", x"69", x"65", x"20", x"30", x"20", x"64", x"6F", x"20", x"34", x"36", x"30", x"30", x"30", x"0A"
    );
    -- Projekt kalkulatora na ZAMPF
    --Filip Kapelanski i Hubert Kowalczyk
    -----------------------------------
    --Konstruowanie dzialan:
    --<liczba1>{Enter}<dzialanie>{Enter}<liczba2>{Enter}
    --gdzie liczba1 i 2 miesci sie w zakresie 0 do 46000
    begin
    if rising_edge (i_Clk) then
        o_TX_DV <= '0';
        if wyswietlono_komunikat = '0' then
            if msg_cooldown_cnt > 0 then
                o_TX_DV <= '0';
                msg_cooldown_cnt := msg_cooldown_cnt - 1;
            elsif msg_cooldown_cnt = 0 then
                o_TX_Byte <= WELCOME_ROM(welcome_msg_counter);
                o_TX_DV <= '1';
                welcome_msg_counter := welcome_msg_counter + 1;
                msg_cooldown_cnt := 1100;
            end if;
            
            if welcome_msg_counter > 225 then
                wyswietlono_komunikat := '1';
                o_wyswietlono_komunikat <= '1';
                o_TX_DV <= '0';
            end if;
            
        end if;
        
        if i_reset = '1' then
            decoder_raw_buffer := 0;
            char_pending := false; 
            negative := false;
            digits_buffer := (others => 0);
            counter := 0;
            o_TX_DV <= '0';
            cooldown_cnt  := 30;
            wyswietlono_komunikat := '0';
            o_wyswietlono_komunikat <= '0';
            welcome_msg_counter := 0;   
        end if;
            
        buf_decoder : if i_result_rdy = '1' then
            decoder_raw_buffer := to_integer(unsigned(i_result));
            negative := false;
            digits_buffer := (others => 0);
            digits_length := 1;
            factor := 10000;
            counter := 5;
    
            if decoder_raw_buffer < 0 then -- nie dotyczy i nie będzie
                negative           := true;
                decoder_raw_buffer := decoder_raw_buffer * (-1);
            end if;
        end if buf_decoder;
            
        if counter > 0 then 
              --   32767 3 digits_length = 5. 2 digits_length = 4. 7 d_l = 3. 6 d_l = 2. 7 d_l = 1
            if (decoder_raw_buffer mod factor) /= decoder_raw_buffer then
                digits_buffer(counter-1)   := decoder_raw_buffer / factor;
                decoder_raw_buffer := decoder_raw_buffer - (digits_buffer(counter-1) * factor);
                
                if digits_length = 1 then -- jest git 
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
                if cooldown_cnt > 0 then
                    o_TX_DV <= '0';
                    cooldown_cnt := cooldown_cnt - 1;
                else
    
                    send_type : if negative then -- narazie nigdy nie wejdzie
                        o_TX_Byte      <= X"2D";
                        o_TX_DV <= '1';
                        negative        := false;
                        cooldown_cnt  := 30; -- czekaj minimum 30 taktów
    
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
                        cooldown_cnt  := 30; -- czekaj 30 taktów
                        digits_length := digits_length - 1;
    
                    else
                        o_TX_Byte      <= X"0A";
                        o_TX_DV <= '1';
                        char_pending    := false;
                        cooldown_cnt := 30;
                    end if send_type;
                end if;
            else
                --o_TX_DV <= '0';
                --decoder_raw_buffer := 0;
                --decoder_raw_buffer2 := 0;
            end if do_send_char;
            
        
       
    end if;
    
end process p_RESULT_PARSER;

end Behavioral;
