library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_accel_activity1 is
  generic (SCLK_T : integer := 10**5); -- 10**6 for sim, 10**5 for hardware
  port (
    resetn : in  std_logic;
    clock  : in  std_logic;
    sel    : in  std_logic_vector(1 downto 0);

    ODATA_LEDS : out std_logic_vector(15 downto 0);

    -- 7-seg
    segs : out std_logic_vector(6 downto 0);
    AN   : out std_logic_vector(7 downto 0);

    -- SPI
    nCS  : out std_logic;
    MOSI : out std_logic;
    MISO : in  std_logic;
    SCLK : out std_logic
  );
end entity;

architecture rtl of top_accel_activity1 is

  component wr_reg_axl362
    generic (SCLK_T: INTEGER := 16);
    port (
      resetn, clock : in std_logic;
      start         : in std_logic;
      address, data : in std_logic_vector(7 downto 0);
      wr_rd         : in std_logic;
      odata         : out std_logic_vector(7 downto 0);
      done          : out std_logic;
      nCS           : out std_logic;
      MOSI          : out std_logic;
      MISO          : in std_logic;
      SCLK          : out std_logic
    );
  end component;

  component my_rege
    generic (N: INTEGER := 8);
    port (
      clock, resetn : in std_logic;
      E, sclr       : in std_logic;
      D             : in std_logic_vector(N-1 downto 0);
      Q             : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component serializer8
    generic (COUNT_REFRESH : integer := 50000);
    port (
      resetn, clock : in std_logic;
      A, B, C, D, E, F, G, H : in std_logic_vector(3 downto 0);
      segs : out std_logic_vector(6 downto 0);
      AN   : out std_logic_vector(7 downto 0)
    );
  end component;

  type state_t is (S1, S2, S3, S4, S5, S6, S7, S8);
  signal st : state_t := S1;

  signal start, wr_rd, done : std_logic;
  signal address, data, odata : std_logic_vector(7 downto 0);

  -- i: 0..7 for 0x0E..0x15
  signal i_cnt : unsigned(2 downto 0) := (others => '0');
  -- j: 0..3 for 0x08..0x0B
  signal j_cnt : unsigned(1 downto 0) := (others => '0');

  signal E_i, E_j : std_logic;

  signal en_hi : std_logic_vector(7 downto 0);
  signal en_lo : std_logic_vector(3 downto 0);

  signal hi_bytes : std_logic_vector(63 downto 0); -- 8 bytes
  signal lo_bytes : std_logic_vector(31 downto 0); -- 4 bytes

  -- low-precision / status
  signal XDATA, YDATA, ZDATA, STATUS : std_logic_vector(7 downto 0);

  -- high-precision bytes
  signal X_L, X_H, Y_L, Y_H, Z_L, Z_H, T_L, T_H : std_logic_vector(7 downto 0);

  -- sign-extended 16-bit values
  signal X16, Y16, Z16, T16 : std_logic_vector(15 downto 0);

begin

  spi0: wr_reg_axl362
    generic map (SCLK_T => SCLK_T)
    port map (
      resetn  => resetn,
      clock   => clock,
      start   => start,
      address => address,
      data    => data,
      wr_rd   => wr_rd,
      odata   => odata,
      done    => done,
      nCS     => nCS,
      MOSI    => MOSI,
      MISO    => MISO,
      SCLK    => SCLK
    );

  -- one-hot enables for the 8 high-precision registers
  en_hi <= (others => '0') when E_i = '0' else
           std_logic_vector(shift_left(to_unsigned(1, 8), to_integer(i_cnt)));

  -- one-hot enables for the 4 low-precision/status registers
  en_lo <= (others => '0') when E_j = '0' else
           std_logic_vector(shift_left(to_unsigned(1, 4), to_integer(j_cnt)));

  -- store 0x0E..0x15
  gen_hi: for k in 0 to 7 generate
    r_hi: my_rege
      generic map (N => 8)
      port map (
        clock  => clock,
        resetn => resetn,
        E      => en_hi(k),
        sclr   => '0',
        D      => odata,
        Q      => hi_bytes((k*8)+7 downto (k*8))
      );
  end generate;

  -- store 0x08..0x0B
  gen_lo: for k in 0 to 3 generate
    r_lo: my_rege
      generic map (N => 8)
      port map (
        clock  => clock,
        resetn => resetn,
        E      => en_lo(k),
        sclr   => '0',
        D      => odata,
        Q      => lo_bytes((k*8)+7 downto (k*8))
      );
  end generate;

  -- low-precision bytes
  XDATA  <= lo_bytes(7 downto 0);
  YDATA  <= lo_bytes(15 downto 8);
  ZDATA  <= lo_bytes(23 downto 16);
  STATUS <= lo_bytes(31 downto 24);

  -- high-precision bytes from 0x0E..0x15
  -- register order:
  -- 0x0E X_L, 0x0F X_H, 0x10 Y_L, 0x11 Y_H,
  -- 0x12 Z_L, 0x13 Z_H, 0x14 T_L, 0x15 T_H
  X_L <= hi_bytes(7 downto 0);
  X_H <= hi_bytes(15 downto 8);
  Y_L <= hi_bytes(23 downto 16);
  Y_H <= hi_bytes(31 downto 24);
  Z_L <= hi_bytes(39 downto 32);
  Z_H <= hi_bytes(47 downto 40);
  T_L <= hi_bytes(55 downto 48);
  T_H <= hi_bytes(63 downto 56);

  -- 12-bit measurement sign-extended to 16 bits
  X16 <= (15 downto 12 => X_H(3)) & X_H(3 downto 0) & X_L;
  Y16 <= (15 downto 12 => Y_H(3)) & Y_H(3 downto 0) & Y_L;
  Z16 <= (15 downto 12 => Z_H(3)) & Z_H(3 downto 0) & Z_L;
  T16 <= (15 downto 12 => T_H(3)) & T_H(3 downto 0) & T_L;

  -- 8 seven-seg displays: |X|Y|Z|ST|
  sdisp: serializer8
  generic map (COUNT_REFRESH => 50000)
  port map (
    resetn => resetn,
    clock  => clock,

    -- rightmost pair = STATUS
    A => STATUS(3 downto 0),
    B => STATUS(7 downto 4),

    -- next pair = Z
    C => ZDATA(3 downto 0),
    D => ZDATA(7 downto 4),

    -- next pair = Y
    E => YDATA(3 downto 0),
    F => YDATA(7 downto 4),

    -- leftmost pair = X
    G => XDATA(3 downto 0),
    H => XDATA(7 downto 4),

    segs => segs,
    AN   => AN
  );

  -- state register
  process(resetn, clock)
  begin
    if resetn = '0' then
      st    <= S1;
      i_cnt <= (others => '0');
      j_cnt <= (others => '0');
    elsif rising_edge(clock) then
      case st is
        when S1 =>
          st <= S2;

        when S2 =>
          if done = '1' then
            st <= S3;
          end if;

        when S3 =>
          st <= S4;

        when S4 =>
          if done = '1' then
            st <= S5;
          end if;

        when S5 =>
          st <= S6;

        when S6 =>
          if done = '1' then
            if i_cnt = 7 then
              i_cnt <= (others => '0');
              st    <= S7;
            else
              i_cnt <= i_cnt + 1;
              st    <= S5;
            end if;
          end if;

        when S7 =>
          st <= S8;

        when S8 =>
          if done = '1' then
            if j_cnt = 3 then
              j_cnt <= (others => '0');
              st    <= S5;
            else
              j_cnt <= j_cnt + 1;
              st    <= S7;
            end if;
          end if;
      end case;
    end if;
  end process;

  -- FSM outputs
  process(st, i_cnt, j_cnt, done)
  begin
    start   <= '0';
    wr_rd   <= '0';
    address <= (others => '0');
    data    <= (others => '0');
    E_i     <= '0';
    E_j     <= '0';

    case st is
      -- write SOFT_RESET = 0x52 to 0x1F
      when S1 =>
        address <= x"1F";
        data    <= x"52";
        wr_rd   <= '1';
        start   <= '1';

      -- wait done
      when S2 =>
        null;

      -- write POWER_CTL = 0x02 to 0x2D
      when S3 =>
        address <= x"2D";
        data    <= x"02";
        wr_rd   <= '1';
        start   <= '1';

      -- wait done
      when S4 =>
        null;

      -- read 0x0E + i
      when S5 =>
        address <= std_logic_vector(to_unsigned(16#0E#, 8) + resize(i_cnt, 8));
        data    <= x"FF";
        wr_rd   <= '0';
        start   <= '1';

      -- latch one high-precision byte when done
      when S6 =>
        if done = '1' then
          E_i <= '1';
        end if;

      -- read 0x08 + j
      when S7 =>
        address <= std_logic_vector(to_unsigned(16#08#, 8) + resize(j_cnt, 8));
        data    <= x"FF";
        wr_rd   <= '0';
        start   <= '1';

      -- latch one low-precision/status byte when done
      when S8 =>
        if done = '1' then
          E_j <= '1';
        end if;

      when others =>
        null;
    end case;
  end process;

  -- LED output selected by sel
  process(sel, X16, Y16, Z16, T16)
  begin
    case sel is
      when "00" =>
        ODATA_LEDS <= X16;
      when "01" =>
        ODATA_LEDS <= Y16;
      when "10" =>
        ODATA_LEDS <= Z16;
      when others =>
        ODATA_LEDS <= T16;
    end case;
  end process;

end architecture;