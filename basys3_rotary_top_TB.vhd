library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity basys3_rotary_top_TB is
end entity;

architecture basys3_rotary_top_TB_ARCH of basys3_rotary_top_TB is
    --==========================================
    -- UUT Signals
    --==========================================
    signal clk  : std_logic := '0';
    signal btnC : std_logic := '0';
    signal ja   : std_logic_vector(3 downto 0) := (others => '0');
    signal led  : std_logic_vector(15 downto 0);
    signal seg  : std_logic_vector(6 downto 0);
    signal an   : std_logic_vector(3 downto 0);
    signal dp   : std_logic;

    constant clkPeriod : time := 10 ns;  -- 100 MHz clock

begin
    --==========================================
    -- Unit Under Test: basys3_top
    --==========================================
    UUT : entity work.basys3_top
        port map (
            clk  => clk,
            btnC => btnC,
            JA   => ja,
            led  => led,
            seg  => seg,
            an   => an,
            dp   => dp
        );

    --==========================================
    -- Clock Generation
    --==========================================
    clockProcess : process
    begin
        while true loop
            clk <= '0';
            wait for clkPeriod / 2;
            clk <= '1';
            wait for clkPeriod / 2;
        end loop;
    end process clockProcess;

    --==========================================
    -- Stimulus Process
    --==========================================
    Test : process
        --======================================
        -- Clockwise Step Procedure
        --======================================
        procedure cwStep is
        begin
            ja(1) <= '0';  -- B
            ja(0) <= '0';  -- A
            wait for 20 ns;
            ja(0) <= '1';  -- rising edge = CW
            wait for 20 ns;
            ja(0) <= '0';
            wait for 20 ns;
        end procedure cwStep;

        --======================================
        -- Counterclockwise Step Procedure
        --======================================
        procedure ccwStep is
        begin
            ja(1) <= '1';  -- B
            ja(0) <= '0';  -- A
            wait for 20 ns;
            ja(0) <= '1';  -- rising edge = CCW
            wait for 20 ns;
            ja(0) <= '0';
            wait for 20 ns;
        end procedure ccwStep;

    begin
        --======================================
        -- Reset Sequence
        --======================================
        ja   <= (others => '0');
        btnC <= '1';
        wait for 20 ns;
        btnC <= '0';
        wait for 20 ns;

        --======================================
        -- Clockwise Rotations
        --======================================
        cwStep; cwStep; cwStep; cwStep;
        cwStep; cwStep; cwStep; cwStep;
        cwStep; cwStep; cwStep; cwStep;
        wait for 50 ns;

        --======================================
        -- Button Press (JA(2))
        --======================================
        ja(2) <= '1';
        wait for 20 ns;
        ja(2) <= '0';
        wait for 20 ns;

        --======================================
        -- CCW Steps
        --======================================
        ccwStep; ccwStep; ccwStep; ccwStep;
        ccwStep; ccwStep; ccwStep; ccwStep;
        ccwStep; ccwStep; ccwStep; ccwStep;

        wait;
    end process;

end basys3_rotary_top_TB_ARCH;
