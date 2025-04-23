library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    generic(
        ADDR_WIDTH      : natural              := 32;
        DATA_WIDTH      : natural              := 32;
        TIMER_ADDR_SPACE_BITS : natural        :=  8; -- Registers address space size bit width
        RST_ACT_LEVEL   : natural range 0 to 1 :=  1
    );
    port (
        CLK               : in  std_logic;
        RST               : in  std_logic;
        REQUEST           : in  std_logic_vector(1 downto 0);
        ADDRESS           : in  std_logic_vector(ADDR_WIDTH -1 downto 0);
        DATA_IN           : in  std_logic_vector(DATA_WIDTH- 1 downto 0);
        RESPONSE          : out std_logic_vector( 2 downto 0); 
        DATA_OUT          : out std_logic_vector(DATA_WIDTH -1 downto 0);
        P_IRQ             : out std_logic
    );
end entity timer;

architecture RTL of timer is

    -- request command constants
    constant CP_REQ_NONE           : unsigned(1 downto 0) := "00";
    constant CP_REQ_READ           : unsigned(1 downto 0) := "01";
    constant CP_REQ_WRITE          : unsigned(1 downto 0) := "10";
    constant CP_REQ_RESERVED       : unsigned(1 downto 0) := "11";
    
    -- command response constants
    constant CP_RSP_IDLE           : unsigned(2 downto 0) := "000";
    constant CP_RSP_ACK            : unsigned(2 downto 0) := "001";
    constant CP_RSP_WAIT           : unsigned(2 downto 0) := "010";
    constant CP_RSP_ERROR          : unsigned(2 downto 0) := "011";
    constant CP_RSP_UNALIGNED      : unsigned(2 downto 0) := "100";
    constant CP_RSP_OOR            : unsigned(2 downto 0) := "101";
    
    ----------------------------------------------------------------------------------
    -- signals and registers
    signal re_d, re_q                       : std_logic;
    signal we_d, we_q                       : std_logic;
    signal bus_data_rd                      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal bus_data_wr_d                    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal bus_data_wr_q                    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal bus_addr_d, bus_addr_q           : std_logic_vector( TIMER_ADDR_SPACE_BITS - 1 downto 0);
    signal bus_resp, bus_resp_d, bus_resp_q : unsigned(2 downto 0);

    ----------------------------------------------------------------------------------
    -- timer registers address constants
    constant TIMER_CNT     : std_logic_vector(TIMER_ADDR_SPACE_BITS - 1 downto 0) := X"00"; -- Timer Count Register, read/write
    constant TIMER_CMP     : std_logic_vector(TIMER_ADDR_SPACE_BITS - 1 downto 0) := X"04"; -- Timer Compare Register, read/write
    constant TIMER_CR      : std_logic_vector(TIMER_ADDR_SPACE_BITS - 1 downto 0) := X"08"; -- Timer Control Register, read/write
    constant TIMER_CYCLE_L : std_logic_vector(TIMER_ADDR_SPACE_BITS - 1 downto 0) := X"10"; -- 64b Cycle Counter, low word, read-only
    constant TIMER_CYCLE_H : std_logic_vector(TIMER_ADDR_SPACE_BITS - 1 downto 0) := X"14"; -- 64b Cycle Counter, high word, read-only

    ----------------------------------------------------------------------------------
    -- timer modes
    constant DISABLED     : std_logic_vector(1 downto 0) := "00";
    constant AUTO_RESTART : std_logic_vector(1 downto 0) := "01";
    constant ONE_SHOT     : std_logic_vector(1 downto 0) := "10";
    constant CONTINUOUS   : std_logic_vector(1 downto 0) := "11"; 
    
    ---------------------------------------------------------------------------------
    -- timer specific registers
    signal cnt_reg_q, cnt_reg_d  : unsigned(31 downto 0);
    signal cmp_reg_q, cmp_reg_d  : unsigned(31 downto 0);
    signal ctrl_reg_q, ctrl_reg_d : std_logic_vector(1 downto 0);   

    -- 64b cycle counter
    signal cycle_cnt : unsigned(63 downto 0);
    
    -- Reset signal value
    constant RST_LEVEL    : std_logic := to_unsigned(RST_ACT_LEVEL, 1)(0);

begin

    ----------------------------------------------------------------------------------
    -- setting of response
    -- considering requests: read, write
    -- address range checked during request phase
    -- address must be aligned to 32b words
    -- bus_resp_d <=
    --     CP_RSP_IDLE     when ((unsigned(REQUEST) /= CP_REQ_READ) and 
    --                           (unsigned(REQUEST) /= CP_REQ_WRITE)) else
    --     CP_RSP_ERROR     when (unsigned(REQUEST) = CP_REQ_RESERVED) else
    --     CP_RSP_UNALIGNED when (ADDRESS(1 downto 0) /= "00") else
    --     CP_RSP_OOR       when (unsigned(ADDRESS(ADDR_WIDTH - 1 downto TIMER_ADDR_SPACE_BITS)) /= 0) else 
    --     CP_RSP_ACK;
    
    -- corrected
    bus_resp_d <=
    CP_RSP_IDLE      when unsigned(REQUEST) = CP_REQ_NONE       else
    CP_RSP_ERROR     when unsigned(REQUEST) = CP_REQ_RESERVED   else
    CP_RSP_OOR       when unsigned(
                        ADDRESS(TIMER_ADDR_SPACE_BITS-1 downto 0)
                      ) > unsigned(TIMER_CYCLE_H)               else
    CP_RSP_UNALIGNED when ADDRESS(1 downto 0) /= "00"            else
    CP_RSP_ACK;

    ----------------------------------------------------------------------------------
    -- setting of help signals
    re_d        <= '1' when (unsigned(REQUEST) = CP_REQ_READ)  and (bus_resp_d = CP_RSP_ACK) else '0';
    we_d        <= '1' when (unsigned(REQUEST) = CP_REQ_WRITE) and (bus_resp_d = CP_RSP_ACK) else '0';
    bus_addr_d  <= ADDRESS(TIMER_ADDR_SPACE_BITS - 1 downto 0) when ((re_d = '1') or (we_d = '1')) else bus_addr_q;
    bus_data_wr_d <= DATA_IN;

    ----------------------------------------------------------------------------------
    -- setting of help signals
    process (CLK, RST) begin
        if (RST = '0') then
            re_q       <= '0';
            we_q       <= '0';
            bus_resp_q <= CP_RSP_IDLE;
            bus_addr_q <= (others => '0');
            bus_data_wr_q <= (others => '0');
        elsif rising_edge(CLK) then
            re_q       <= re_d;
            we_q       <= we_d;
            bus_resp_q <= bus_resp_d;
            bus_addr_q <= bus_addr_d;
            bus_data_wr_q <= bus_data_wr_d;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- setting of timer registers
    process (CLK, RST) begin
        if (RST = '0') then
            cnt_reg_q  <= (others => '0');
            cmp_reg_q  <= (others => '0');
            ctrl_reg_q <= (others => '0');
        elsif rising_edge(CLK) then
            cnt_reg_q  <= cnt_reg_d;
            cmp_reg_q  <= cmp_reg_d;
            ctrl_reg_q <= ctrl_reg_d;
        end if;
    end process;

    -- 64b cycle counter
    process (CLK, RST) begin
        if rising_edge(clk) then
            if (RST = RST_LEVEL)   then
                cycle_cnt <= (others => '0');
            else
                cycle_cnt <= cycle_cnt + 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- next state logic for peripheral registers
    process (we_q, re_q, bus_addr_q, bus_data_wr_q, cnt_reg_q, cmp_reg_q, ctrl_reg_q, cycle_cnt) begin
        cnt_reg_d   <= cnt_reg_q;
        cmp_reg_d   <= cmp_reg_q;
        ctrl_reg_d  <= ctrl_reg_q;

        bus_data_rd <= (others => '0');
        bus_resp    <= CP_RSP_IDLE;

        -- counting 
        case ctrl_reg_q is
            -- incrementing cnt_reg, if value in cmp_reg reached then restart of cnt_reg from 0
            when AUTO_RESTART =>
                if (cnt_reg_q = cmp_reg_q) then
                    cnt_reg_d  <= (others => '0');
                else
                    cnt_reg_d  <= cnt_reg_q + 1;
                end if;
            -- incrementing cnt_reg, if value in cmp_reg reached then disabling of the counter
            when ONE_SHOT     =>
                if (cnt_reg_q = cmp_reg_q) then
                    cnt_reg_d  <= (others => '0');
                    ctrl_reg_d <= (others => '0');
                else
                    cnt_reg_d  <= cnt_reg_q + 1;
                end if;
            -- continuos counting
            when CONTINUOUS   =>
                cnt_reg_d  <= cnt_reg_q + 1;
            -- disabling counter
            when DISABLED     =>
                    null;
            when others       =>
                    null;
        end case;
        
        -- read/write data from/to peripheral registers
        -- read
        if (re_q = '1') then                    
            -- read value of counter register
            if (bus_addr_q = TIMER_CNT) then              
                bus_data_rd <= std_logic_vector(resize(unsigned(cnt_reg_q), DATA_WIDTH));
                bus_resp    <= CP_RSP_ACK;
            -- read value of compare register
            elsif (bus_addr_q = TIMER_CMP) then  
                bus_data_rd <= std_logic_vector(resize(unsigned(cmp_reg_q), DATA_WIDTH));
                bus_resp    <= CP_RSP_ACK;
            -- read value of control register
            elsif (bus_addr_q = TIMER_CR) then                
                bus_data_rd <= std_logic_vector(resize(unsigned(ctrl_reg_q), DATA_WIDTH));
                bus_resp    <= CP_RSP_ACK;
            -- read value of 64b Cycle Counter, low word
            elsif (bus_addr_q = TIMER_CYCLE_L) then          
                bus_data_rd <= std_logic_vector(cycle_cnt(31 downto 0));
                bus_resp    <= CP_RSP_ACK;
            -- read value of 64b Cycle Counter, high word
            elsif (bus_addr_q = TIMER_CYCLE_H) then          
                bus_data_rd <= std_logic_vector(cycle_cnt(63 downto 32));
                bus_resp    <= CP_RSP_ACK;
            else
                bus_resp    <= CP_RSP_ACK;
            end if;
        -- write
        elsif (we_q = '1') then             
            -- write value of new counter - to the counter register
            if (bus_addr_q = TIMER_CNT) then              
                cnt_reg_d  <= unsigned(bus_data_wr_q);
                bus_resp   <= CP_RSP_ACK;
            -- write value to which the counter will be compared - to compare register
            elsif (bus_addr_q = TIMER_CMP) then              
                cmp_reg_d <= unsigned(bus_data_wr_q);
                bus_resp   <= CP_RSP_ACK;
            -- write value to control register which determines the operation of timer
            elsif (bus_addr_q = TIMER_CR)  then                
                ctrl_reg_d <= bus_data_wr_q(1 downto 0);
                bus_resp   <= CP_RSP_ACK;
            else
                bus_resp   <= CP_RSP_ACK;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- setting outputs
    RESPONSE <= std_logic_vector(bus_resp) when (bus_resp_q = CP_RSP_ACK) else std_logic_vector(bus_resp_q);
    DATA_OUT <= bus_data_rd;

    ----------------------------------------------------------------------------------
    -- setting outputs interrupt signal
    P_IRQ <= '1' when (ctrl_reg_q /= DISABLED) and (cnt_reg_q = cmp_reg_q) else '0'; 

end architecture RTL;
