###############################################################################
## Copyright (C) 2023 Analog Devices, Inc. All rights reserved.
## Modified for custom data capture (replacing SPI Engine)
### SPDX short identifier: ADIBSD
###############################################################################

source [file join [file dirname [info script]] tq15eg_2023_1.tcl]
source ./zu_system_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

# Add custom VHDL sources for module references
# These must be added before sourcing the block design script
set custom_src_dir "/home/neutrino/Documents/hdl-2022_r2_p1/projects/ad4134_fmc/tq15eg_data"
add_files -norecurse [list \
    "$custom_src_dir/ad4134_data.vhd" \
    "$custom_src_dir/ad4134_axis_packer.vhd"]
update_compile_order -fileset sources_1

# Use custom data capture with AXI DMAC
source ./ad4134_bd_dmac.tcl

# ------------------------------------------------------------------------------
# ILA for debugging (matching original custom design)
# ------------------------------------------------------------------------------

ad_ip_instance ila ila_adc
ad_ip_parameter ila_adc CONFIG.C_MONITOR_TYPE Native
ad_ip_parameter ila_adc CONFIG.C_ADV_TRIGGER true
ad_ip_parameter ila_adc CONFIG.C_EN_STRG_QUAL 1
ad_ip_parameter ila_adc CONFIG.C_DATA_DEPTH 8192
ad_ip_parameter ila_adc CONFIG.C_NUM_OF_PROBES 7
ad_ip_parameter ila_adc CONFIG.C_PROBE0_WIDTH 1   ;# odr_out
ad_ip_parameter ila_adc CONFIG.C_PROBE1_WIDTH 1   ;# dclk_out
ad_ip_parameter ila_adc CONFIG.C_PROBE2_WIDTH 1   ;# ad4134_din
ad_ip_parameter ila_adc CONFIG.C_PROBE3_WIDTH 1   ;# data_rdy
ad_ip_parameter ila_adc CONFIG.C_PROBE4_WIDTH 1   ;# tvalid
ad_ip_parameter ila_adc CONFIG.C_PROBE5_WIDTH 1   ;# tready
ad_ip_parameter ila_adc CONFIG.C_PROBE6_WIDTH 32  ;# tdata[31:0]

# Connect ILA clock (use data capture clock)
ad_connect $data_clk ila_adc/clk

# Connect probes
ad_connect ad4134_data_0/odr_out ila_adc/probe0
ad_connect ad4134_data_0/dclk_out ila_adc/probe1
ad_connect ad4134_din0 ila_adc/probe2
ad_connect ad4134_data_0/data_rdy ila_adc/probe3
ad_connect ad4134_axis_0/m_axis_tvalid ila_adc/probe4
ad_connect ad4134_axis_0/m_axis_tready ila_adc/probe5

# Slice lower 32 bits of AXIS data for ILA
ad_ip_instance xlslice slice_axis_tdata
ad_ip_parameter slice_axis_tdata CONFIG.DIN_WIDTH 128
ad_ip_parameter slice_axis_tdata CONFIG.DIN_FROM 31
ad_ip_parameter slice_axis_tdata CONFIG.DIN_TO 0
ad_connect ad4134_axis_0/m_axis_tdata slice_axis_tdata/Din
ad_connect slice_axis_tdata/Dout ila_adc/probe6

