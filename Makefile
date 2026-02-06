####################################################################################
## Copyright (c) 2018 - 2023 Analog Devices, Inc.
## Modified for custom data capture (no SPI Engine)
### SPDX short identifier: BSD-1-Clause
####################################################################################

PROJECT_NAME := ad4134_fmc_tq15eg

# Custom VHDL sources from AD4134_git
#CUSTOM_SRC_DIR := /home/neutrino/work/AD4134_git/src

M_DEPS += ad4134_bd_custom.tcl
M_DEPS += ../../scripts/adi_pd.tcl
M_DEPS += ./system_constr.xdc
M_DEPS += ./zu_system_bd.tcl
M_DEPS += ../../../library/common/ad_iobuf.v
# M_DEPS += $(CUSTOM_SRC_DIR)/ad4134_data.vhd

# Library dependencies (removed SPI Engine, kept basic IPs)
LIB_DEPS += axi_clkgen
LIB_DEPS += axi_hdmi_tx
LIB_DEPS += axi_i2s_adi
LIB_DEPS += axi_spdif_tx
LIB_DEPS += axi_sysid
LIB_DEPS += sysid_rom
LIB_DEPS += util_i2c_mixer

include ../../scripts/project-xilinx.mk

