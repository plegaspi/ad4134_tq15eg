library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ad4134_data is
    generic(
        NUM_CHANNELS : integer := 4;
        DATA_WIDTH : integer := 24;
        ODR_HIGH_TIME  : integer := 3;
        ODR_LOW_TIME   : integer := 24;
        ODR_WAIT_FIRST : integer := 1;
        ODR_WAIT_LAST  : integer := 3
    );
    port(
        -- Global signals:
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        
        -- AD4134 signals:
        data_in    : in std_logic_vector(NUM_CHANNELS -1 downto 0);
        dclk_out   : out std_logic;
        odr_out    : out std_logic;
        
    
        -- Output signals:
        data_out : out std_logic_vector(NUM_CHANNELS*DATA_WIDTH-1 downto 0);
        data_rdy   : out std_logic
    );
end ad4134_data;

architecture rtl of ad4134_data is

    -- Constants:
    constant SYS_CLK_FREQ   : integer := 50_000_000; --UNUSED
    constant DIG_CLK_FREQ   : integer := 10_000_000; --UNUSED


    -- Internal control registers:
    signal odr_cnt   : integer range 0 to ODR_LOW_TIME + ODR_HIGH_TIME;
    signal odr_int   : std_logic := '0';
    signal dclk_int  : std_logic := '0';
    signal bit_count : integer range 0 to DATA_WIDTH;

    signal shift_reg  : std_logic_vector(NUM_CHANNELS*DATA_WIDTH - 1 downto 0);

    -- ODR Tracker signals:
    constant ODR_TOTAL_CLKS : integer := ODR_HIGH_TIME + ODR_WAIT_FIRST + ODR_LOW_TIME + ODR_WAIT_LAST; -- 30 clock cycles, @ 10 MHz that is
    signal   odr_tracker    : integer range 0 to ODR_TOTAL_CLKS;

    -- Flags:
    signal dclk_active : std_logic;

    -- Slower clocks for data interface:
    -- slow_clk is kept as a signal for dclk_out only; logic uses clock enables
    signal slow_clk : std_logic;
    constant SLOW_CLK_MAX : integer := 1;
    signal slow_clk_counter : integer range 0 to SLOW_CLK_MAX;

    -- Clock enables: combinatorial pulses on the clk edges where slow_clk would rise/fall
    signal slow_clk_r_en : std_logic;  -- rising edge of slow_clk
    signal slow_clk_f_en : std_logic;  -- falling edge of slow_clk

    -- Read flags:
    signal data_rdy_flag : std_logic;

begin

    dclk_int <= slow_clk; -- FOR NOW. Have to add generics to set up the clock and sample speeds

    dclk_out <= dclk_int when dclk_active = '1' else '0';

    odr_out <= odr_int;

    -- Combinatorial clock enables: high for one clk cycle at the slow_clk edge
    slow_clk_r_en <= '1' when (slow_clk_counter = SLOW_CLK_MAX and slow_clk = '0') else '0';
    slow_clk_f_en <= '1' when (slow_clk_counter = SLOW_CLK_MAX and slow_clk = '1') else '0';


    slow_clk_p : process(clk, rst_n) is
    begin
        if (rst_n = '0') then

            slow_clk <= '0';
            slow_clk_counter <= 0;

        elsif (rising_edge(clk)) then

            if (slow_clk_counter < SLOW_CLK_MAX) then
                slow_clk_counter <= slow_clk_counter + 1;
            else
                slow_clk_counter <= 0;
                slow_clk <= not slow_clk;
            end if;

        end if;
    end process;


    odr_p : process(clk, rst_n) is
    begin
        if (rst_n = '0') then

            odr_tracker <= 0;
            odr_int     <= '0';

            -- Flags:
            dclk_active <= '0';

        elsif (rising_edge(clk)) then

            if (slow_clk_r_en = '1') then

                case odr_tracker is

                    when 0 to ODR_HIGH_TIME - 1 => -- 0:2

                        odr_int <= '1';

                        dclk_active <= '0';

                    when ODR_HIGH_TIME to ODR_HIGH_TIME + ODR_WAIT_FIRST - 1 => -- 3:3

                        odr_int     <= '0';

                        dclk_active <= '0';

                    when ODR_HIGH_TIME + ODR_WAIT_FIRST to ODR_HIGH_TIME + ODR_WAIT_FIRST + ODR_LOW_TIME - 1 => -- 4:27

                        odr_int     <= '0';

                        dclk_active <= '1';

                    when ODR_HIGH_TIME + ODR_WAIT_FIRST + ODR_LOW_TIME to ODR_HIGH_TIME + ODR_WAIT_FIRST + ODR_LOW_TIME + ODR_WAIT_LAST - 1 => -- 28:29

                        odr_int     <= '0';

                        dclk_active <= '0';

                    when others =>

                        odr_int     <= '0';

                        dclk_active <= '0';

                end case;

                if (odr_tracker < ODR_TOTAL_CLKS) then
                    odr_tracker <= odr_tracker + 1;
                else
                    odr_tracker <= 0;
                end if;

            end if;

        end if;
    end process;


    read_p : process(clk, rst_n) is
    begin
        if (rst_n = '0') then

            bit_count <= DATA_WIDTH;

            shift_reg <= (others => '0');
            data_out <= (others => '0');

            data_rdy <= '0';

            data_rdy_flag <= '0';

        elsif (rising_edge(clk)) then

            if (slow_clk_f_en = '1') then

                if (dclk_active = '1') then

                    if (bit_count > 0) then

                        for ch in 0 to NUM_CHANNELS-1 loop
                            shift_reg(ch*DATA_WIDTH + (bit_count-1)) <= data_in(ch);
                        end loop;


                        bit_count <= bit_count - 1;

                    else

                        data_out <= shift_reg;

                        bit_count <= DATA_WIDTH;


                    end if;

                    data_rdy <= '0';

                else

                    if (bit_count = 0 and data_rdy_flag = '0') then -- this means the previous else was skipped

                        data_out <= shift_reg;


                        data_rdy_flag <= '1';

                        bit_count <= DATA_WIDTH;

                    elsif (data_rdy_flag = '1') then

                        data_rdy <= '1';
                        data_rdy_flag <= '0';

                    else

                        data_rdy_flag <= '0';
                        data_rdy <= '0';

                    end if;

                end if;

            end if;

        end if;
    end process;


end rtl;

