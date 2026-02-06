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

# ad4134 data interface

set_property -dict {PACKAGE_PIN AA7  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_dclk];   ## FMC_LPC_CLK0_M2C_P
set_property -dict {PACKAGE_PIN Y3  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_din0]; ## FMC_LPC_LA00_N_CC
set_property -dict {PACKAGE_PIN AC1  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_din1]; ## FMC_LPC_LA06_N
set_property -dict {PACKAGE_PIN V2  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_din2]; ## FMC_LPC_LA02_P
set_property -dict {PACKAGE_PIN V1  IOSTANDARD LVCMOS18 IOB TRUE} [get_ports ad4134_din3]; ## FMC_LPC_LA02_N
set_property -dict {PACKAGE_PIN Y4  IOSTANDARD LVCMOS18} [get_ports ad4134_odr];             ## FMC_LPC_LA00_P_CC

# ad4134 GPIO lines

set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS18} [get_ports ad4134_resetn];          ## FMC_LPC_LA16_P
set_property -dict {PACKAGE_PIN U5  IOSTANDARD LVCMOS18} [get_ports ad4134_pdn];             ## FMC_LPC_LA07_P
set_property -dict {PACKAGE_PIN AA2  IOSTANDARD LVCMOS18} [get_ports ad4134_mode];            ## FMC_LPC_LA04_P
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio0];           ## FMC_LPC_LA10_P
set_property -dict {PACKAGE_PIN W4  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio1];           ## FMC_LPC_LA10_N
set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS18} [get_ports ad4134_gpio2];           ## FMC_LPC_LA11_P
set_property -dict {PACKAGE_PIN AB5  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio3];           ## FMC_LPC_LA11_N
set_property -dict {PACKAGE_PIN W7  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio4];           ## FMC_LPC_LA12_P
set_property -dict {PACKAGE_PIN W6  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio5];           ## FMC_LPC_LA12_N
set_property -dict {PACKAGE_PIN AB8  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio6];           ## FMC_LPC_LA13_P
set_property -dict {PACKAGE_PIN AC8  IOSTANDARD LVCMOS18} [get_ports ad4134_gpio7];           ## FMC_LPC_LA13_N
set_property -dict {PACKAGE_PIN AC2  IOSTANDARD LVCMOS18} [get_ports ad4134_pinbspi];         ## FMC_LPC_LA06_P
set_property -dict {PACKAGE_PIN AC7  IOSTANDARD LVCMOS18} [get_ports ad4134_dclkio];          ## FMC_LPC_LA14_P
set_property -dict {PACKAGE_PIN AC6  IOSTANDARD LVCMOS18} [get_ports ad4134_dclk_mode];       ## FMC_LPC_LA14_N
