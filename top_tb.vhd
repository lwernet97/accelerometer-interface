library ieee;
use ieee.std_logic_1164.all;

entity tb_top_accel_activity1 is
end;

architecture sim of tb_top_accel_activity1 is
  component top_accel_activity1
    generic (SCLK_T : integer := 16);
    port (
      resetn : in  std_logic;
      clock  : in  std_logic;
      sel    : in  std_logic_vector(1 downto 0);
      ODATA_LEDS : out std_logic_vector(15 downto 0);
      nCS  : out std_logic;
      MOSI : out std_logic;
      MISO : in  std_logic;
      SCLK : out std_logic
    );
  end component;

  signal resetn : std_logic := '0';
  signal clock  : std_logic := '0';
  signal sel    : std_logic_vector(1 downto 0) := "00";
  signal ODATA_LEDS : std_logic_vector(15 downto 0);
  signal nCS, MOSI, SCLK : std_logic;
  signal MISO : std_logic := '1';

  constant clock_period : time := 10 ns;
begin

  uut: top_accel_activity1
    generic map (SCLK_T => 16)
    port map (
      resetn => resetn,
      clock => clock,
      sel => sel,
      ODATA_LEDS => ODATA_LEDS,
      nCS => nCS, MOSI => MOSI, MISO => MISO, SCLK => SCLK
    );

  clock_process: process
  begin
    clock <= '0'; wait for clock_period/2;
    clock <= '1'; wait for clock_period/2;
  end process;

  stim: process
  begin
    wait for 100 ns;
    wait for clock_period*10; resetn <= '1';

    sel <= "00";  -- show X on LEDs
    -- MISO already '1'
    wait;
  end process;
end;