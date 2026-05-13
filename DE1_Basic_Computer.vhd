LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY DE1_Basic_Computer IS
PORT (
    CLOCK_50 : IN STD_LOGIC;
    CLOCK_27 : IN STD_LOGIC;
    KEY      : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
    SW       : IN STD_LOGIC_VECTOR (9 DOWNTO 0);

    UART_RXD : IN STD_LOGIC;

    GPIO_0 : INOUT STD_LOGIC_VECTOR (35 DOWNTO 0);
    GPIO_1 : INOUT STD_LOGIC_VECTOR (35 DOWNTO 0);

    SRAM_DQ : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);
    DRAM_DQ : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);

    LEDG : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    LEDR : OUT STD_LOGIC_VECTOR (9 DOWNTO 0);

    HEX0 : OUT STD_LOGIC_VECTOR (0 TO 6);
    HEX1 : OUT STD_LOGIC_VECTOR (0 TO 6);
    HEX2 : OUT STD_LOGIC_VECTOR (0 TO 6);
    HEX3 : OUT STD_LOGIC_VECTOR (0 TO 6);

    SRAM_ADDR : OUT STD_LOGIC_VECTOR (17 DOWNTO 0);
    SRAM_CE_N : OUT STD_LOGIC;
    SRAM_WE_N : OUT STD_LOGIC;
    SRAM_OE_N : OUT STD_LOGIC;
    SRAM_UB_N : OUT STD_LOGIC;
    SRAM_LB_N : OUT STD_LOGIC;

    UART_TXD : OUT STD_LOGIC;

    DRAM_ADDR  : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
    DRAM_BA_1  : BUFFER STD_LOGIC;
    DRAM_BA_0  : BUFFER STD_LOGIC;
    DRAM_CAS_N : OUT STD_LOGIC;
    DRAM_RAS_N : OUT STD_LOGIC;
    DRAM_CLK   : OUT STD_LOGIC;
    DRAM_CKE   : OUT STD_LOGIC;
    DRAM_CS_N  : OUT STD_LOGIC;
    DRAM_WE_N  : OUT STD_LOGIC;
    DRAM_UDQM  : BUFFER STD_LOGIC;
    DRAM_LDQM  : BUFFER STD_LOGIC
);
END DE1_Basic_Computer;

ARCHITECTURE DE1_Basic_Computer_rtl OF DE1_Basic_Computer IS

COMPONENT nios_system
    PORT (
        clk  : IN STD_LOGIC;
        reset_n : IN STD_LOGIC;

        GPIO_0_to_and_from_the_Expansion_JP1 :
            INOUT STD_LOGIC_VECTOR (31 DOWNTO 0);

        GPIO_1_to_and_from_the_Expansion_JP2 :
            INOUT STD_LOGIC_VECTOR (31 DOWNTO 0);

        LEDG_from_the_Green_LEDs :
            OUT STD_LOGIC_VECTOR (7 DOWNTO 0);

        KEY_to_the_Pushbuttons :
            IN STD_LOGIC_VECTOR (3 DOWNTO 0);

        LEDR_from_the_Red_LEDs :
            OUT STD_LOGIC_VECTOR (9 DOWNTO 0);

        SRAM_ADDR_from_the_SRAM :
            OUT STD_LOGIC_VECTOR (17 DOWNTO 0);

        SRAM_CE_N_from_the_SRAM :
            OUT STD_LOGIC;

        SRAM_DQ_to_and_from_the_SRAM :
            INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);

        SRAM_LB_N_from_the_SRAM :
            OUT STD_LOGIC;

        SRAM_OE_N_from_the_SRAM :
            OUT STD_LOGIC;

        SRAM_UB_N_from_the_SRAM :
            OUT STD_LOGIC;

        SRAM_WE_N_from_the_SRAM :
            OUT STD_LOGIC;

        UART_RXD_to_the_Serial_port :
            IN STD_LOGIC;

        UART_TXD_from_the_Serial_port :
            OUT STD_LOGIC;

        SW_to_the_Slider_switches :
            IN STD_LOGIC_VECTOR (9 DOWNTO 0);

        zs_addr_from_the_sdram :
            OUT STD_LOGIC_VECTOR (11 DOWNTO 0);

        zs_ba_from_the_sdram :
            BUFFER STD_LOGIC_VECTOR (1 DOWNTO 0);

        zs_cas_n_from_the_sdram :
            OUT STD_LOGIC;

        zs_cke_from_the_sdram :
            OUT STD_LOGIC;

        zs_cs_n_from_the_sdram :
            OUT STD_LOGIC;

        zs_dq_to_and_from_the_sdram :
            INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);

        zs_dqm_from_the_sdram :
            BUFFER STD_LOGIC_VECTOR (1 DOWNTO 0);

        zs_ras_n_from_the_sdram :
            OUT STD_LOGIC;

        zs_we_n_from_the_sdram :
            OUT STD_LOGIC;

        to_hex_export :
            OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
END COMPONENT;

COMPONENT sdram_pll
    PORT (
        inclk0 : IN STD_LOGIC;
        c0     : OUT STD_LOGIC;
        c1     : OUT STD_LOGIC
    );
END COMPONENT;

COMPONENT hex7seg
    PORT (
        hex     : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        display : OUT STD_LOGIC_VECTOR(0 TO 6)
    );
END COMPONENT;

SIGNAL system_clock : STD_LOGIC;

SIGNAL BA  : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL DQM : STD_LOGIC_VECTOR(1 DOWNTO 0);

SIGNAL to_HEX : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

DRAM_BA_1 <= BA(1);
DRAM_BA_0 <= BA(0);

DRAM_UDQM <= DQM(1);
DRAM_LDQM <= DQM(0);

GPIO_0(0)  <= 'Z';
GPIO_0(2)  <= 'Z';
GPIO_0(16) <= 'Z';
GPIO_0(18) <= 'Z';

GPIO_1(0)  <= 'Z';
GPIO_1(2)  <= 'Z';
GPIO_1(16) <= 'Z';
GPIO_1(18) <= 'Z';

NiosII : nios_system
PORT MAP(
    clk      => system_clock,
    reset_n  => KEY(0),

    SW_to_the_Slider_switches => SW,
    KEY_to_the_Pushbuttons => (KEY(3 DOWNTO 1) & "1"),

    GPIO_0_to_and_from_the_Expansion_JP1(0)
        => GPIO_0(1),

    GPIO_0_to_and_from_the_Expansion_JP1(13 DOWNTO 1)
        => GPIO_0(15 DOWNTO 3),

    GPIO_0_to_and_from_the_Expansion_JP1(14)
        => GPIO_0(17),

    GPIO_0_to_and_from_the_Expansion_JP1(31 DOWNTO 15)
        => GPIO_0(35 DOWNTO 19),

    GPIO_1_to_and_from_the_Expansion_JP2(0)
        => GPIO_1(1),

    GPIO_1_to_and_from_the_Expansion_JP2(13 DOWNTO 1)
        => GPIO_1(15 DOWNTO 3),

    GPIO_1_to_and_from_the_Expansion_JP2(14)
        => GPIO_1(17),

    GPIO_1_to_and_from_the_Expansion_JP2(31 DOWNTO 15)
        => GPIO_1(35 DOWNTO 19),

    LEDG_from_the_Green_LEDs => LEDG,
    LEDR_from_the_Red_LEDs => LEDR,

    SRAM_ADDR_from_the_SRAM => SRAM_ADDR,
    SRAM_CE_N_from_the_SRAM => SRAM_CE_N,
    SRAM_DQ_to_and_from_the_SRAM => SRAM_DQ,
    SRAM_LB_N_from_the_SRAM => SRAM_LB_N,
    SRAM_OE_N_from_the_SRAM => SRAM_OE_N,
    SRAM_UB_N_from_the_SRAM => SRAM_UB_N,
    SRAM_WE_N_from_the_SRAM => SRAM_WE_N,

    UART_RXD_to_the_Serial_port => UART_RXD,
    UART_TXD_from_the_Serial_port => UART_TXD,

    zs_addr_from_the_sdram => DRAM_ADDR,
    zs_ba_from_the_sdram => BA,
    zs_cas_n_from_the_sdram => DRAM_CAS_N,
    zs_cke_from_the_sdram => DRAM_CKE,
    zs_cs_n_from_the_sdram => DRAM_CS_N,
    zs_dq_to_and_from_the_sdram => DRAM_DQ,
    zs_dqm_from_the_sdram => DQM,
    zs_ras_n_from_the_sdram => DRAM_RAS_N,
    zs_we_n_from_the_sdram => DRAM_WE_N,

    to_hex_export => to_HEX
);

neg_3ns : sdram_pll
PORT MAP (
    inclk0 => CLOCK_50,
    c0     => DRAM_CLK,
    c1     => system_clock
);

H0 : hex7seg
PORT MAP (
    hex     => to_HEX(3 DOWNTO 0),
    display => HEX0
);

H1 : hex7seg
PORT MAP (
    hex     => to_HEX(7 DOWNTO 4),
    display => HEX1
);

H2 : hex7seg
PORT MAP (
    hex     => to_HEX(11 DOWNTO 8),
    display => HEX2
);

H3 : hex7seg
PORT MAP (
    hex     => to_HEX(15 DOWNTO 12),
    display => HEX3
);

END DE1_Basic_Computer_rtl;
