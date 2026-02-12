###############################################################################
## Copyright (C) 2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

# gpio_i/o/t and spi0_* are BD ports connected internally by system_top.v
# (gpio via ad_iobuf, spi0 via top-level port wiring) - not physical I/O
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]

# ad4134 SPI configuration interface
set_property -dict {PACKAGE_PIN Y2  IOSTANDARD LVCMOS18} [get_ports ad4134_spi_sdi];         ## FMC_LPC_LA03_P
set_property -dict {PACKAGE_PIN AA1  IOSTANDARD LVCMOS18} [get_ports ad4134_spi_sdo];         ## FMC_LPC_LA04_N
set_property -dict {PACKAGE_PIN AB4  IOSTANDARD LVCMOS18} [get_ports ad4134_spi_sclk];        ## FMC_LPC_LA01_P_CC
set_property -dict {PACKAGE_PIN AB3  IOSTANDARD LVCMOS18} [get_ports ad4134_spi_cs] ;         ## FMC_LPC_LA05_P

# ad7134 SPI configuration interface

set_property -dict {PACKAGE_PIN AH1 IOSTANDARD LVCMOS18} [get_ports ad7134_spi_sdi];         ## FMC_LPC_LA03_P
set_property -dict {PACKAGE_PIN AF1 IOSTANDARD LVCMOS18} [get_ports ad7134_spi_sdo];         ## FMC_LPC_LA04_N
set_property -dict {PACKAGE_PIN AJ6 IOSTANDARD LVCMOS18} [get_ports ad7134_spi_sclk];        ## FMC_LPC_LA01_P_CC
set_property -dict {PACKAGE_PIN AG3 IOSTANDARD LVCMOS18} [get_ports ad7134_spi_cs[0]];          ## FMC_LPC_LA05_P
set_property -dict {PACKAGE_PIN AH3 IOSTANDARD LVCMOS18} [get_ports ad7134_spi_cs[1]];          ## FMC_LPC_LA05_N

# ad4134 data interface

set_property -dict {PACKAGE_PIN AA7  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_dclk];   ## FMC_LPC_CLK0_M2C_P
set_property -dict {PACKAGE_PIN Y3  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports  ad4134_din[0]]; ## FMC_LPC_LA00_N_CC
set_property -dict {PACKAGE_PIN AC1  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_din[1]]; ## FMC_LPC_LA06_N
set_property -dict {PACKAGE_PIN V2  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports  ad4134_din[2]]; ## FMC_LPC_LA02_P
set_property -dict {PACKAGE_PIN V1  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports  ad4134_din[3]]; ## FMC_LPC_LA02_N
set_property -dict {PACKAGE_PIN Y4  IOSTANDARD LVCMOS18} [get_ports ad4134_odr];             ## FMC_LPC_LA00_P_CC

# ad7134 data interface

set_property -dict {PACKAGE_PIN AE7 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_dclk];   ## FMC_LPC_CLK0_M2C_P
set_property -dict {PACKAGE_PIN AF5 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[0]];    ## FMC_LPC_LA00_N_CC
set_property -dict {PACKAGE_PIN AJ2 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[1]];    ## FMC_LPC_LA06_N
set_property -dict {PACKAGE_PIN AD2 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[2]];    ## FMC_LPC_LA02_P
set_property -dict {PACKAGE_PIN AD1 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[3]];    ## FMC_LPC_LA02_N
set_property -dict {PACKAGE_PIN AE3 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[4]];    ## FMC_LPC_LA08_P
set_property -dict {PACKAGE_PIN AF3 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[5]];    ## FMC_LPC_LA08_N
set_property -dict {PACKAGE_PIN AE2 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[6]];    ## FMC_LPC_LA09_P
set_property -dict {PACKAGE_PIN AE1 IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad7134_din[7]];    ## FMC_LPC_LA09_N
set_property -dict {PACKAGE_PIN AE5 IOSTANDARD LVCMOS18} [get_ports ad7134_odr];             ## FMC_LPC_LA00_P_CC

# ad4134 GPIO lines

set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS18} [get_ports ad4134_resetn];          ## FMC_LPC_LA16_P
set_property -dict {PACKAGE_PIN U5  IOSTANDARD LVCMOS18} [get_ports ad4134_pdn];             ## FMC_LPC_LA07_P
set_property -dict {PACKAGE_PIN AA2  IOSTANDARD LVCMOS18} [get_ports ad4134_mode];            ## FMC_LPC_LA04_P
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS18} [get_ports  ad4134_gpio[0]];           ## FMC_LPC_LA10_P
set_property -dict {PACKAGE_PIN W4  IOSTANDARD LVCMOS18} [get_ports  ad4134_gpio[1]];           ## FMC_LPC_LA10_N
set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS18} [get_ports  ad4134_gpio[2]];           ## FMC_LPC_LA11_P
set_property -dict {PACKAGE_PIN AB5  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio[3]];           ## FMC_LPC_LA11_N
set_property -dict {PACKAGE_PIN W7  IOSTANDARD LVCMOS18} [get_ports  ad4134_gpio[4]];           ## FMC_LPC_LA12_P
set_property -dict {PACKAGE_PIN W6  IOSTANDARD LVCMOS18} [get_ports  ad4134_gpio[5]];           ## FMC_LPC_LA12_N
set_property -dict {PACKAGE_PIN AB8  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio[6]];           ## FMC_LPC_LA13_P
set_property -dict {PACKAGE_PIN AC8  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio[7]];           ## FMC_LPC_LA13_N
set_property -dict {PACKAGE_PIN AC2  IOSTANDARD LVCMOS18} [get_ports ad4134_pinbspi];         ## FMC_LPC_LA06_P
set_property -dict {PACKAGE_PIN AC7  IOSTANDARD LVCMOS18} [get_ports ad4134_dclkio];          ## FMC_LPC_LA14_P
set_property -dict {PACKAGE_PIN AC6  IOSTANDARD LVCMOS18} [get_ports ad4134_dclk_mode];       ## FMC_LPC_LA14_N

# ad7134 GPIO lines
set_property -dict {PACKAGE_PIN AG10 IOSTANDARD LVCMOS18} [get_ports ad7134_resetn[0]];          ## FMC_LPC_LA16_P
set_property -dict {PACKAGE_PIN AG9 IOSTANDARD LVCMOS18} [get_ports ad7134_resetn[1]];          ## FMC_LPC_LA16_N
set_property -dict {PACKAGE_PIN AD4 IOSTANDARD LVCMOS18} [get_ports ad7134_pdn[0]];             ## FMC_LPC_LA07_P
set_property -dict {PACKAGE_PIN AE4 IOSTANDARD LVCMOS18} [get_ports ad7134_pdn[1]];             ## FMC_LPC_LA07_N
set_property -dict {PACKAGE_PIN AF2 IOSTANDARD LVCMOS18} [get_ports ad7134_mode[0]];            ## FMC_LPC_LA04_P
set_property -dict {PACKAGE_PIN AJ1 IOSTANDARD LVCMOS18} [get_ports ad7134_mode[1]];            ## FMC_LPC_LA03_N
set_property -dict {PACKAGE_PIN AH4 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[0]];           ## FMC_LPC_LA10_P
set_property -dict {PACKAGE_PIN AJ4 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[1]];           ## FMC_LPC_LA10_N
set_property -dict {PACKAGE_PIN AE8 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[2]];           ## FMC_LPC_LA11_P
set_property -dict {PACKAGE_PIN AF8 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[3]];           ## FMC_LPC_LA11_N
set_property -dict {PACKAGE_PIN AD7 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[4]];           ## FMC_LPC_LA12_P
set_property -dict {PACKAGE_PIN AD6 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[5]];           ## FMC_LPC_LA12_N
set_property -dict {PACKAGE_PIN AG8 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[6]];           ## FMC_LPC_LA13_P
set_property -dict {PACKAGE_PIN AH8 IOSTANDARD LVCMOS18} [get_ports ad7134_gpio[7]];           ## FMC_LPC_LA13_N
set_property -dict {PACKAGE_PIN AH7 IOSTANDARD LVCMOS18} [get_ports ad7134_dclkio[0]];          ## FMC_LPC_LA14_P
set_property -dict {PACKAGE_PIN AD10 IOSTANDARD LVCMOS18} [get_ports ad7134_dclkio[1]];          ## FMC_LPC_LA15_P
set_property -dict {PACKAGE_PIN AH2 IOSTANDARD LVCMOS18} [get_ports ad7134_pinbspi];         ## FMC_LPC_LA06_P
set_property -dict {PACKAGE_PIN AH6 IOSTANDARD LVCMOS18} [get_ports ad7134_dclkmode];        ## FMC_LPC_LA14_N
