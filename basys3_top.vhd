library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity basys3_top is
    port(
        clk  : in  std_logic;
        btnC : in  std_logic;                       -- center button as reset
        JA   : in  std_logic_vector(3 downto 0);    -- PmodENC on JA1..JA4
        led  : out std_logic_vector(15 downto 0);
        seg  : out std_logic_vector(6 downto 0);
        an   : out std_logic_vector(3 downto 0);
        dp   : out std_logic
    );
end entity;

architecture basys3_top_ARCH of basys3_top is

    signal resetN   : std_logic;
    signal btnClean : std_logic;
    signal aClean   : std_logic;
    signal bClean   : std_logic;

    component rotary_encoder_core is
        port(
            clk    : in  std_logic;
            resetN : in  std_logic;
            encA   : in  std_logic;
            encB   : in  std_logic;
            encBtn : in  std_logic;
            leds   : out std_logic_vector(15 downto 0);
            seg    : out std_logic_vector(6 downto 0);
            an     : out std_logic_vector(3 downto 0);
            dp     : out std_logic
        );
    end component;

    component debounce is
        generic(
            COUNT_MAX : integer := 1000000
        );
        port(
            clk    : in  std_logic;
            resetN : in  std_logic;
            noisy  : in  std_logic;
            clean  : out std_logic
        );
    end component;

begin
    -- btnC is active-high, make active-low reset
    resetN <= not btnC;

    -- Debounce encoder button (JA(2)) - slower (~2 ms)
    debBtn : debounce
        generic map(COUNT_MAX => 200000)
        port map(
            clk    => clk,
            resetN => resetN,
            noisy  => JA(2),
            clean  => btnClean
        );

    -- Debounce encoder A (JA(0)) - faster (~50 us)
    debA : debounce
        generic map(COUNT_MAX => 5000)
        port map(
            clk    => clk,
            resetN => resetN,
            noisy  => JA(0),
            clean  => aClean
        );

    -- Debounce encoder B (JA(1)) - faster (~50 us)
    debB : debounce
        generic map(COUNT_MAX => 5000)
        port map(
            clk    => clk,
            resetN => resetN,
            noisy  => JA(1),
            clean  => bClean
        );

    basys3 : rotary_encoder_core
        port map(
            clk    => clk,
            resetN => resetN,
            encA   => aClean,
            encB   => bClean,
            encBtn => btnClean,
            leds   => led,
            seg    => seg,
            an     => an,
            dp     => dp
        );

end basys3_top_ARCH;
