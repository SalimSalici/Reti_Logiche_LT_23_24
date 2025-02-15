library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_add : in std_logic_vector(15 downto 0);
        i_k   : in std_logic_vector(9 downto 0);
        
        o_done : out std_logic;
        
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in  std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is
    component fsm_mod is
        port(
            i_clk, i_rst, i_start, o_done, valid: in std_logic;
            o_mem_en, o_mem_we: out std_logic;
            state: out std_logic_vector(2 downto 0)
        );
    end component fsm_mod;
    
    component addr_mod is
        port(
            i_clk, i_rst, valid, i_start: in std_logic;
            state: in std_logic_vector(2 downto 0);
            i_k: in std_logic_vector(9 downto 0);
            i_add: in std_logic_vector(15 downto 0);
            o_done: out std_logic;
            o_mem_addr: out std_logic_vector(15 downto 0)
        );
    end component addr_mod;
    
    component completer_mod is
        port(
            i_clk, i_rst: in std_logic;
            state: in std_logic_vector(2 downto 0);
            i_mem_data: in std_logic_vector(7 downto 0);
            valid: out std_logic;
            o_mem_data: out std_logic_vector(7 downto 0)
        );
    end component completer_mod;
    
    signal done, valid: std_logic;
    signal state: std_logic_vector(2 downto 0);

begin

    fsm_mod_1: fsm_mod
        port map(
            i_clk => i_clk,
            i_rst => i_rst,
            i_start => i_start,
            o_done => done,
            valid => valid,
            o_mem_en => o_mem_en,
            o_mem_we => o_mem_we,
            state => state
        );
        
    addr_mod_1: addr_mod
        port map(
            i_clk => i_clk,
            i_rst => i_rst,
            valid => valid,
            i_start => i_start,
            state => state,
            i_k => i_k,
            i_add => i_add,
            o_done => done,
            o_mem_addr => o_mem_addr
        );
        
    completer_mod_1: completer_mod
        port map(
            i_clk => i_clk,
            i_rst => i_rst,
            state => state,
            i_mem_data => i_mem_data,
            valid => valid,
            o_mem_data => o_mem_data
        );
        
    o_done <= done;

end project_reti_logiche_arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_mod is
    port(
        i_clk, i_rst, i_start, o_done, valid: in std_logic;
        o_mem_en, o_mem_we: out std_logic;
        state: out std_logic_vector(2 downto 0)
    );
end fsm_mod;

architecture fsm_mod_arch of fsm_mod is
    type state_type is (RESET, IDLE, READ, WRITE_VAL_OR_CRED, WRITE_CRED, DONE);
    signal next_state, current_state: state_type;
begin

    fsm_reg: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            current_state <= RESET;
        elsif rising_edge(i_clk) then
            current_state <= next_state;
        else 
            current_state <= current_state;
        end if;
    end process;
    
    fsm_transitions: process(current_state, i_rst, i_start, o_done, valid)
    begin
        next_state <= RESET;
        case current_state is
            when RESET =>
                if i_rst = '0' then
                    next_state <= IDLE;
                else
                    next_state <= RESET;
                end if;
            when IDLE =>
                if i_start = '1' then
                    next_state <= READ;
                else
                    next_state <= IDLE;
                end if;
            when READ =>
                if o_done = '0' then
                    next_state <= WRITE_VAL_OR_CRED;
                else
                    next_state <= DONE;
                end if;
            when WRITE_VAL_OR_CRED =>
                if valid = '0' then
                    next_state <= WRITE_CRED;
                else 
                    next_state <= READ;
                end if;
            when WRITE_CRED =>
                next_state <= READ;
            when DONE =>
                if i_start = '0' then
                    next_state <= IDLE;
                else
                    next_state <= DONE;
                end if;
        end case;
    end process;
    
    fsm_out: process(current_state)
    begin
        o_mem_en <= '0';
        o_mem_we <= '0';
        case current_state is
            when RESET =>
                state <= "000";
                o_mem_en <= '0';
                o_mem_we <= '0';
            when IDLE =>
                state <= "001";
                o_mem_en <= '0';
                o_mem_we <= '0';
            when READ =>
                state <= "010";
                o_mem_en <= '1';
                o_mem_we <= '0';
            when WRITE_VAL_OR_CRED =>
                state <= "011";
                o_mem_en <= '1';
                o_mem_we <= '1';
            when WRITE_CRED =>
                state <= "100";
                o_mem_en <= '1';
                o_mem_we <= '1';
            when DONE =>
                state <= "101";
                o_mem_en <= '0';
                o_mem_we <= '0';
        end case;
    end process;
    
end fsm_mod_arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addr_mod is
    port(
        i_clk, i_rst, valid, i_start: in std_logic;
        state: in std_logic_vector(2 downto 0);
        i_k: in std_logic_vector(9 downto 0);
        i_add: in std_logic_vector(15 downto 0);
        o_done: out std_logic;
        o_mem_addr: out std_logic_vector(15 downto 0)
    );
end addr_mod;

architecture addr_mod_arch of addr_mod is
    signal offset: unsigned(10 downto 0);
    
    -- offset_correction is a signale used to write 
    -- directly the credibility of a value in 
    -- case that the value read in the READ state is valid
    signal offset_correction: unsigned(10 downto 0);
  
    signal final_offset: unsigned(10 downto 0);
    signal done: std_logic;
begin

    process(i_rst, i_clk)
    begin
        if i_rst = '1' then
            offset <= (others => '0');
            done <= '0';
        elsif rising_edge(i_clk) then
            done <= '0';
            case state is
                when "000" => --  RESET state
                    offset <= (others => '0');
                when "001" => -- IDLE state
                    offset <= (others => '0');
                    if i_k = "0000000000" and i_start = '1' then
                        done <= '1';
                    end if;
                when "010" => -- READ state
                    offset <= offset;
                    if offset >= final_offset or i_k = "0000000000" then
                        done <= '1';
                    end if;
                when "011" => -- WRITE_VAL_OR_CRED state
                    if valid = '0' then
                        offset <= offset + 1;
                    else 
                        offset <= offset + 2;
                        if (offset + 2) >= final_offset then
                            done <= '1';
                        end if;
                    end if;
                when "100" => -- WRITE_CRED state
                    offset <= offset + 1;
                    if offset >= final_offset then
                        done <= '1';
                    end if;
                when "101" => -- DONE state
                    offset <= offset; 
                    if i_start = '1' then
                        done <= '1';
                    end if; 
                when others =>
                    done <= done;
                    offset <= offset; 
            end case;
        else
            done <= done;
            offset <= offset;
        end if;
    end process;
    
    -- constant signal used to verify the termination condition of an elaboration
    final_offset <= unsigned(i_k & '0') - 1; -- (i_k * 2) - 1
    
    -- if valid is equal to 1 then we must write directly the credibility ==> offset_correction is set to 1
    -- otherwise offset_correction is set to 0
    offset_correction <= unsigned(std_logic_vector'("0000000000" & valid));
    
    o_mem_addr <= std_logic_vector(unsigned(i_add) + offset + offset_correction);
    o_done <= '1' when state = "101" else done;

end addr_mod_arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity completer_mod is
    port(
        i_clk, i_rst: in std_logic;
        state: in std_logic_vector(2 downto 0);
        i_mem_data: in std_logic_vector(7 downto 0);
        valid: out std_logic;
        o_mem_data: out std_logic_vector(7 downto 0)
    );
end completer_mod;

architecture completer_mod_arch of completer_mod is
    signal last_value: std_logic_vector(7 downto 0);
    signal credibility: std_logic_vector(4 downto 0);
    constant max_credibility: std_logic_vector(4 downto 0) := "11111";
begin

    process(i_rst, i_clk)
    begin
        if i_rst = '1' then
            last_value <= (others => '0');
            credibility <= "00000";
        elsif rising_edge(i_clk) then
            case state is
                when "001" => -- IDLE state
                    last_value <= (others => '0');
                    credibility <= "00000";
                when "011" => -- WRITE_VAL_OR_CRED state
                    if i_mem_data = "00000000" then
                        if credibility > "00000" then
                            credibility <= std_logic_vector(unsigned(credibility) - 1);
                        else 
                            credibility <= "00000";
                        end if;
                        last_value <= last_value;
                    else
                        credibility <= max_credibility;
                        last_value <= i_mem_data;
                    end if;
                when others =>
                    credibility <= credibility;
                    last_value <= last_value;
            end case;
        else
            last_value <= last_value;
            credibility <= credibility;
        end if;
    end process;
    
    -- "011" is the WRITE_VAL_OR_CRED state; "100" is the WRITE_CRED state
    o_mem_data <= last_value                when state = "011" and i_mem_data = "00000000" else
                  "000" & max_credibility   when state = "011" and i_mem_data /= "00000000" else
                  "000" & credibility       when state = "100" else
                  (others => '0');
    
    -- "011" is the WRITE_VAL_OR_CRED state
    valid <= '0' when state = "011" and i_mem_data = "00000000" else
             '1' when state = "011" and i_mem_data /= "00000000" else
             '0';

end completer_mod_arch;