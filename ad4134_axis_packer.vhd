library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- AD4134 AXI-Stream Packer
-- Packs four 24-bit channels into a single 128-bit AXIS beat:
-- [127:96]=CH3, [95:64]=CH2, [63:32]=CH1, [31:0]=CH0 (zero-extended)

entity ad4134_axis_packer is
    generic(
        DATA_WIDTH     : integer := 24;
        DATA_IN_WIDTH  : integer := 12;
        TDATA_WIDTH    : integer := 512
    );
    port(
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        data_in0       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_in1       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in2       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in3       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in4       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_in5       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in6       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in7       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in8       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_in9       : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in10      : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_in11      : in  std_logic_vector(DATA_WIDTH - 1  downto 0);
        data_rdy       : in  std_logic;
        m_axis_tready  : in  std_logic;
        m_axis_tvalid  : out std_logic;
        m_axis_tdata   : out std_logic_vector(TDATA_WIDTH - 1 downto 0);
        m_axis_tlast   : out std_logic
    );
end ad4134_axis_packer;

architecture rtl of ad4134_axis_packer is
    signal tvalid_r     : std_logic := '0';
    signal tdata_r      : std_logic_vector(TDATA_WIDTH - 1 downto 0) := (others => '0');
    -- Edge detection for data_rdy (CDC: data_rdy is from slow_clk domain ~490kHz)
    signal data_rdy_d1  : std_logic := '0';
    signal data_rdy_d2  : std_logic := '0';
    signal data_rdy_rising : std_logic;
begin

    m_axis_tvalid <= tvalid_r;
    m_axis_tdata  <= tdata_r;
    -- tlast must be LOW for multi-sample transfers!
    -- DMAC completes based on X_LENGTH byte count, not tlast
    -- Setting tlast=1 on every sample causes DMAC to stop after 1 sample
    m_axis_tlast  <= '0';

    -- Rising edge detection with 2-stage synchronizer for CDC
    data_rdy_rising <= data_rdy_d1 and (not data_rdy_d2);

    process(clk, rst_n)
    begin
        if (rst_n = '0') then
            tvalid_r    <= '0';
            tdata_r     <= (others => '0');
            data_rdy_d1 <= '0';
            data_rdy_d2 <= '0';
        elsif (rising_edge(clk)) then
            -- 2-stage synchronizer for data_rdy from slow_clk domain
            data_rdy_d1 <= data_rdy;
            data_rdy_d2 <= data_rdy_d1;

            -- Clear valid after handshake (but not if new data arriving same cycle)
            if (tvalid_r = '1' and m_axis_tready = '1' and data_rdy_rising = '0') then
                tvalid_r <= '0';
            end if;

            -- Always latch new data on rising edge of data_rdy
            -- If DMAC isn't ready, overwrite pending data (lose old sample, keep newest)
            if (data_rdy_rising = '1') then
                tdata_r <= x"00000000" &
                           x"00000000" &
                           x"00000000" &
                           x"00000000" &
                           x"00" & data_in11 &
                           x"00" & data_in10 &
                           x"00" & data_in9 &
                           x"00" & data_in8 &
                           x"00" & data_in7 &
                           x"00" & data_in6 &
                           x"00" & data_in5 &
                           x"00" & data_in4 &
                           x"00" & data_in3 &
                           x"00" & data_in2 &
                           x"00" & data_in1 &
                           x"00" & data_in0;
                tvalid_r <= '1';
            end if;
        end if;
    end process;

end rtl;

