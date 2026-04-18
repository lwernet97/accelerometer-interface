library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity serializer8 is
  generic (
    COUNT_REFRESH : integer := 10**5  -- 1 ms @ 100 MHz
  );
  port (
    resetn, clock : in std_logic;

    -- eight hex nibbles, left-to-right across 8 digits
    A, B, C, D, E, F, G, H : in std_logic_vector(3 downto 0);

    segs : out std_logic_vector(6 downto 0); -- CA..CG active-low
    AN   : out std_logic_vector(7 downto 0)  -- AN7..AN0 active-low
  );
end serializer8;

architecture Behavioral of serializer8 is
  component my_genpulse_sclr
    generic (COUNT: INTEGER:= (10**2)/2);
    port (clock, resetn, E, sclr: in std_logic;
          Q: out std_logic_vector ( integer(ceil(log2(real(COUNT)))) - 1 downto 0);
          z: out std_logic);
  end component;

  component hex2sevenseg
    port (hex: in std_logic_vector (3 downto 0);
          leds: out std_logic_vector (6 downto 0));
  end component;

  signal tick : std_logic;
  signal s    : unsigned(2 downto 0) := (others => '0'); -- 0..7
  signal omux : std_logic_vector(3 downto 0);
  signal leds : std_logic_vector(6 downto 0);

begin

  -- refresh tick
  gz: my_genpulse_sclr
    generic map (COUNT => COUNT_REFRESH)
    port map (clock => clock, resetn => resetn, E => '1', sclr => '0', z => tick);

  -- advance digit index on each tick
  process(resetn, clock)
  begin
    if resetn='0' then
      s <= (others => '0');
    elsif rising_edge(clock) then
      if tick='1' then
        s <= s + 1;
      end if;
    end if;
  end process;

  -- 8-to-1 nibble mux
  with std_logic_vector(s) select
    omux <= A when "000",
            B when "001",
            C when "010",
            D when "011",
            E when "100",
            F when "101",
            G when "110",
            H when others;

  -- hex -> segments (leds is active-high "on", board expects active-low)
  seg7: hex2sevenseg port map (hex => omux, leds => leds);
  segs <= not(leds);

  -- active-low one-hot AN
  -- s=000 selects digit 0 (AN(0)=0), s=111 selects digit 7 (AN(7)=0)
  process(s)
    variable an_tmp : std_logic_vector(7 downto 0);
  begin
    an_tmp := (others => '1');
    an_tmp(to_integer(s)) := '0';
    AN <= an_tmp;
  end process;

end Behavioral;