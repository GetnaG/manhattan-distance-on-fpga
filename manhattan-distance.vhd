----------------------------------------------------------------------------------
-- 
-- POLITECNICO DI MILANO - INGEGNERIA INFORMATICA - PROVA FINALE DI RETI LOGICHE 2018/19 - Scaglione Prof. FORNACIARI

-- Alunno: 				FAHED BEN TEJ 
-- Codice Persona : 	10549663
-- Matricola :			871416
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    Port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
-- L' algoritmo esegue dei calcoli in base allo stato in cui si trova
type state_type is (
                        INITIAL_WAIT,
                        COMPUTE_ADDRESS,
                        SET_ADDRESS,
                        WAIT_CLOCK_CYCLE,
                        READ_BYTE,
                        CHECK_VALID,
                        COMPUTE_PARTIAL_DELTAS,
                        COMPUTE_DELTA,
                        CHECK_GREATER,
                        CHECK_EQUAL,
                        CHECK_FINITO,
                        WRITE,
                        DONE_HIGH,
                        WAIT_START_LOW);
signal state : state_type ;
signal k : integer range 0 to 9;
signal indiceMaschera : integer range 0 to 8;
signal distanza, delta : integer range 0 to 512;
signal deltaX,deltaY : integer ;
signal flagIndirizzoNonIniziale : std_logic; -- se il flag è 1 allora non ho ancora letto l'indirizzo 0
signal px, py : std_logic_vector(7 downto 0);
signal cx, cy : std_logic_vector(7 downto 0);
signal flagLeggiX : std_logic ; -- se il flag è 1 allora la prossima lettura è una X, altrimenti è una Y
signal mascheraK : std_logic_vector(7 downto 0);
signal mascheraOut : unsigned( 7 downto 0);                        
signal indirizzo : std_logic_vector(15 downto 0);


begin

process(i_clk, i_rst)



begin
    if(i_rst = '1') then
        state <= INITIAL_WAIT;
    end if;
    if(rising_edge(i_clk)) then
        case state is 
        
        when INITIAL_WAIT =>
        	k <= 1;
            indiceMaschera <= 0;
            distanza <= 512;
            delta <= 512;
            deltaX <= 512;
            deltaY <= 512;
            indirizzo <= "0000000000000000";
            flagIndirizzoNonIniziale <= '0';
            --non inizializzo i punti poichè vengono assegnati in seguito senza essere letti
            flagLeggiX <= '1';
            mascheraK <= "00000000";
            mascheraOut <= "00000000";
            if(i_start = '1') then --inizializza tutto
                 state <= COMPUTE_ADDRESS;
             end if;
             
          when COMPUTE_ADDRESS =>
                --se indirizzo è 0 e non l'ho ancora letto , allora non devo aumentarlo
                --se l'indirizzo è 0 e l'ho letto, allora devo aumentarlo
                if(indirizzo = "0000000000000000" and flagIndirizzoNonIniziale = '0') then
                    -- nulla
                elsif(indirizzo = "0000000000000000" and flagIndirizzoNonIniziale = '1') then
                    indirizzo <="0000000000010001"; --l'indirizo diventa 17
                elsif(indirizzo = "0000000000010001") then
                    indirizzo <= "0000000000010010"; -- indirizzo diventa 18
                elsif (indirizzo = "0000000000010010") then
                    indirizzo <= "0000000000000001"; -- indirizzo diventa 1
                else --l'indirizzo è 1 e deve essere aumentato
                    indirizzo <= indirizzo + "0000000000000001";
                end if;
               o_en <='1';
               o_we <= '0';
               o_address <= indirizzo;
               state <= SET_ADDRESS;
               
          when SET_ADDRESS =>
          if(k = 9) then
          			state <= CHECK_FINITO;
          else
            o_address <= indirizzo;
            state <= WAIT_CLOCK_CYCLE;
           end if;
            
            when WAIT_CLOCK_CYCLE =>
                state <= READ_BYTE;
                
            when READ_BYTE =>
                case indirizzo is
                when "0000000000000000" => -- ho letto la maschere di ingresso
                    mascheraK <= i_data;
                    flagIndirizzoNonIniziale <= '1'; -- ho appena letto l'indirzzo 0
                    state <= COMPUTE_ADDRESS;
                    
                 when "0000000000010001" => -- ho appena letto l'indirzzo 17 (coordinata X punto P)
                    px <= i_data;
                    state <= COMPUTE_ADDRESS;
                 when "0000000000010010" =>
                    py <= i_data;
                    state <= COMPUTE_ADDRESS;
                 when others =>
                    if( flagLeggiX = '1') then
                        cx <= i_data;
                        state <= CHECK_VALID;
                        
                    else 
                        cy <= i_data;
                        state <= CHECK_VALID;
                        
                    end if;
                    
                 o_en <= '0'; 
                 indiceMaschera <= k-1;                  
                end case;
                
               when CHECK_VALID =>
                if( flagLeggiX = '1') then --se ho appena letto un x
                       flagLeggiX <= '0'; 
                       state <= COMPUTE_ADDRESS;
                else -- se ho appena letto un y
                    flagLeggiX <= '1';
                    if(mascheraK(indiceMaschera) = '1') then -- se  ho letto completamente P e P letto appartiene ai K centroidi. mascheraK è zero-indexed
                        state <= COMPUTE_PARTIAL_DELTAS;
                    else
                        k <= k +1;
                        --if(k = 9) then -- ATTENZIONE : PROBLEMA NELL'INCREMENTO NELLA IMMEDIATA SUCCESSIVA LETTURA => CONTROLLO TUTTO; BETTER SAFE THAN SORRY
                        --    state <= CHECK_FINITO ;
                        --else 
                            state <= COMPUTE_ADDRESS;
                        --end if;

                    end if;
                end if;
               
              when COMPUTE_PARTIAL_DELTAS =>
                if( px >= cx) then
                    deltaX <= to_integer(unsigned(px) - unsigned(cx));
                else
                    deltaX <= to_integer(unsigned(cx) - unsigned(px));
                end if;
                
                if( py >= cy) then
                    deltaY <= to_integer(unsigned(py) - unsigned(cy));
                else
                    deltaY <= to_integer(unsigned(cy) - unsigned(py));
                end if;
                state <= COMPUTE_DELTA;
                
             when COMPUTE_DELTA => 
                delta <= deltaX + deltaY;
                state <= CHECK_GREATER;
              
          
                
                
              when CHECK_GREATER =>
                if(distanza > delta) then
                    distanza <= delta;
                    case k is
                        when 1 => mascheraOut <= "00000001";
                        when 2 => mascheraOut <= "00000010";
                        when 3 => mascheraOut <= "00000100";
                        when 4 => mascheraOut <= "00001000";
                        when 5 => mascheraOut <= "00010000";
                        when 6 => mascheraOut <= "00100000";
                        when 7 => mascheraOut <= "01000000";
                        when 8 => mascheraOut <= "10000000";
                        when others =>
                     end case;
                     state <= CHECK_FINITO;
                else state <= CHECK_EQUAL;
                end if;
               
                
             when CHECK_EQUAL =>
                if(distanza = delta) then
                    case k is
                        when 1 => mascheraOut <= mascheraOut + "00000001";
                        when 2 => mascheraOut <= mascheraOut + "00000010";
                        when 3 => mascheraOut <= mascheraOut + "00000100";
                        when 4 => mascheraOut <= mascheraOut + "00001000";
                        when 5 => mascheraOut <= mascheraOut + "00010000";
                        when 6 => mascheraOut <= mascheraOut + "00100000";
                        when 7 => mascheraOut <= mascheraOut + "01000000";
                        when 8 => mascheraOut <= mascheraOut + "10000000";
                        when others => 
                     end case;               
                 end if;
                 state <= CHECK_FINITO;
                                         
             when CHECK_FINITO =>
        
                if(k = 9) then
                    state <= WRITE;
                else state <= COMPUTE_ADDRESS;
                end if;
                k <= k+1;
                
              when WRITE =>
                o_en <= '1';
                o_we <= '1';
                o_address <= "0000000000010011" ; -- indirizo = 19
                o_data <= std_logic_vector(mascheraOut);
                state <= DONE_HIGH ;
                
              when DONE_HIGH => 
                o_en <= '0';
                o_we <= '0';
                o_done <= '1';
                state <= WAIT_START_LOW;
               
               when WAIT_START_LOW =>
                if(i_start = '0') then
                    o_done <= '0';
                    state <= INITIAL_WAIT;
                end if;
                 
                
                
        end case;
    end if ;   
end process;
    


end Behavioral;
