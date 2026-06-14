----------------------------------------------------------------------------------
-- Engineer: Enzo Sidibe
-- Project: Rotary encoder with the Basys3 board.
--   Turning the encoder moves a single LED left or right on the 16-LED bar, one
--   step per click. The seven-segment display shows either the shaft angle or the
--   rpm, and pressing the encoder button switches between these two modes.
--   Active mode is indicated by changing the LED pattern (one LED for rpm,
--   all-but-one for angle) and by using the decimal points on the seven-segment
--   display.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rotary_encoder_core is
    port(
        clk    : in  std_logic;                      -- clock
        resetN : in  std_logic;                      -- active low reset
        encA   : in  std_logic;                      -- PmodENC A
        encB   : in  std_logic;                      -- PmodENC B
        encBtn : in  std_logic;                      -- PmodENC shaft button (active-high)
        leds   : out std_logic_vector(15 downto 0);
        seg    : out std_logic_vector(6 downto 0);
        an     : out std_logic_vector(3 downto 0);
        dp     : out std_logic
    );
end entity;

architecture rotary_encoder_core_ARCH of rotary_encoder_core is
    --===============================================================
    -- SevenSegmentDriver component
    --===============================================================
    component SevenSegmentDriver is
        port(
            reset     : in  std_logic;
            clock     : in  std_logic;
            digit3    : in  std_logic_vector(3 downto 0);
            digit2    : in  std_logic_vector(3 downto 0);
            digit1    : in  std_logic_vector(3 downto 0);
            digit0    : in  std_logic_vector(3 downto 0);
            blank3    : in  std_logic;
            blank2    : in  std_logic;
            blank1    : in  std_logic;
            blank0    : in  std_logic;
            sevenSegs : out std_logic_vector(6 downto 0);
            anodes    : out std_logic_vector(3 downto 0)
        );
    end component;

    --===============================================================
    -- Synchronizers
    --===============================================================
    signal encAMeta, encASync     : std_logic;
    signal encBMeta, encBSync     : std_logic;
    signal encBtnMeta, encBtnSync : std_logic;

    --===============================================================
    -- Quadrature decoding
    --===============================================================
    signal aPrev   : std_logic;
    signal stepCw  : std_logic;
    signal stepCcw : std_logic;

    --===============================================================
    -- Position, RPM, Angle
    --===============================================================
    signal pos       : unsigned(3 downto 0) := (others => '0');
    signal ledPosVec : std_logic_vector(15 downto 0);
    signal btnPrev   : std_logic;
    signal modeRpm   : std_logic;
    signal timeCnt   : integer range 0 to 50000000;
    signal tickCnt   : integer range 0 to 10000;
    signal rpmVal    : integer range 0 to 9999;
    signal angleVal  : integer range 0 to 9999;
    signal dispValue : integer range 0 to 9999;

    --===============================================================
    -- BCD digits
    --===============================================================
    signal d0, d1, d2, d3             : integer range 0 to 9;
    signal dig0, dig1, dig2, dig3     : std_logic_vector(3 downto 0);
    signal blank0, blank1, blank2, blank3 : std_logic;
    signal resetSeven : std_logic;
    signal anInt      : std_logic_vector(3 downto 0);

begin
    resetSeven <= not resetN;

    --===============================================================
    -- Input sync
    --===============================================================
    syncInputs : process(clk)
    begin
        if rising_edge(clk) then
            if resetN = '0' then
                encAMeta   <= '0';
                encASync   <= '0';
                encBMeta   <= '0';
                encBSync   <= '0';
                encBtnMeta <= '0';
                encBtnSync <= '0';
            else
                encAMeta   <= encA;
                encASync   <= encAMeta;
                encBMeta   <= encB;
                encBSync   <= encBMeta;
                encBtnMeta <= encBtn;
                encBtnSync <= encBtnMeta;
            end if;
        end if;
    end process;

    --===============================================================
    -- Quadrature Decoder (1 pulse per detent)
    --===============================================================
    quadDecoder : process(clk)
    begin
        if rising_edge(clk) then
            if resetN = '0' then
                aPrev   <= '0';
                stepCw  <= '0';
                stepCcw <= '0';
            else
                stepCw  <= '0';
                stepCcw <= '0';
                if (aPrev = '0') and (encASync = '1') then
                    if encBSync = '0' then
                        stepCw <= '1';
                    else
                        stepCcw <= '1';
                    end if;
                end if;
                aPrev <= encASync;
            end if;
        end if;
    end process;

    --===============================================================
    -- Position, RPM, Mode toggle
    --===============================================================
    mainLogic : process(clk)
    begin
        if rising_edge(clk) then
            if resetN = '0' then
                pos     <= (others => '0');
                tickCnt <= 0;
                timeCnt <= 0;
                rpmVal  <= 0;
                modeRpm <= '1';
                btnPrev <= '0';
            else
                -- Position update
                if stepCw = '1' then
                    if pos = "1111" then pos <= (others => '0');
                    else pos <= pos + 1; end if;
                elsif stepCcw = '1' then
                    if pos = "0000" then pos <= "1111";
                    else pos <= pos - 1; end if;
                end if;

                -- Tick count for RPM
                if (stepCw = '1') or (stepCcw = '1') then
                    if tickCnt < 10000 then tickCnt <= tickCnt + 1; end if;
                end if;

                -- 0.5 second window
                if timeCnt = 50000000 - 1 then
                    timeCnt <= 0;
                    rpmVal  <= tickCnt * 8;
                    tickCnt <= 0;
                else
                    timeCnt <= timeCnt + 1;
                end if;

                -- Mode toggle (button rising edge)
                btnPrev <= encBtnSync;
                if (btnPrev = '0') and (encBtnSync = '1') then
                    modeRpm <= not modeRpm;
                end if;
            end if;
        end if;
    end process;

    --===============================================================
    -- Angle calculation
    --===============================================================
    angleCalc : process(pos)
    begin
        angleVal <= to_integer(pos) * 23;
    end process;

    --===============================================================
    -- Choose value to display
    --===============================================================
    displaySelect : process(modeRpm, rpmVal, angleVal)
    begin
        if modeRpm = '1' then
            dispValue <= rpmVal;
        else
            dispValue <= angleVal;
        end if;
    end process;

    --===============================================================
    -- Convert integer to BCD
    --===============================================================
    bcdProc : process(dispValue)
        variable v : integer;
    begin
        v := dispValue;
        if v < 0 then v := 0;
        elsif v > 9999 then v := 9999; end if;
        d0 <= v mod 10; v := v / 10;
        d1 <= v mod 10; v := v / 10;
        d2 <= v mod 10; v := v / 10;
        d3 <= v mod 10;
    end process;

    dig0 <= std_logic_vector(to_unsigned(d0, 4));
    dig1 <= std_logic_vector(to_unsigned(d1, 4));
    dig2 <= std_logic_vector(to_unsigned(d2, 4));
    dig3 <= std_logic_vector(to_unsigned(d3, 4));

    blank0 <= '0';
    blank1 <= '0';
    blank2 <= '0';
    blank3 <= '0';

    --===============================================================
    -- LED one-hot
    --===============================================================
    ledPosProc : process(pos)
        variable tmp : std_logic_vector(15 downto 0);
        variable idx : integer;
    begin
        tmp := (others => '0');
        idx := to_integer(pos);
        tmp(idx) := '1';
        ledPosVec <= tmp;
    end process;

    leds <= ledPosVec when modeRpm = '1'
            else not ledPosVec;

    --===============================================================
    -- 7-seg instantiation
    --===============================================================
    sevensegInst : SevenSegmentDriver
        port map(
            reset     => resetSeven,
            clock     => clk,
            digit3    => dig3,
            digit2    => dig2,
            digit1    => dig1,
            digit0    => dig0,
            blank3    => blank3,
            blank2    => blank2,
            blank1    => blank1,
            blank0    => blank0,
            sevenSegs => seg,
            anodes    => anInt
        );

    an <= anInt;

    --===============================================================
    -- Decimal point
    --===============================================================
    dpLogic : process(modeRpm, anInt)
    begin
        dp <= '1';
        if modeRpm = '1' then
            if anInt = "0111" then dp <= '0'; end if;
        else
            if anInt = "1110" then dp <= '0'; end if;
        end if;
    end process;

end rotary_encoder_core_ARCH;
