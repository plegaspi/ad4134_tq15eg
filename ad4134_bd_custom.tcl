###############################################################################
## Copyright (C) 2023-2024 Analog Devices, Inc. All rights reserved.
## Modified for custom data capture (replacing SPI Engine)
### SPDX short identifier: ADIBSD
###############################################################################

# ==============================================================================
# AD4134 Custom Data Capture Block Design
# Replaces SPI Engine with custom VHDL modules for parallel data capture
# Keeps PS SPI0 EMIO for register configuration (configured in zu_system_bd.tcl)
# ==============================================================================

# ------------------------------------------------------------------------------
# Create external ports for AD4134 data interface
# These match the original ad4134_bd.tcl port names for compatibility
# ------------------------------------------------------------------------------

# Data interface ports (directly exposed, no SPI Engine)
create_bd_port -dir I ad4134_din0
create_bd_port -dir I ad4134_din1
create_bd_port -dir I ad4134_din2
create_bd_port -dir I ad4134_din3
create_bd_port -dir O ad4134_dclk
create_bd_port -dir O ad4134_odr

# ------------------------------------------------------------------------------
# Custom VHDL Module (ad4134_data)
# Must be added to the project sources before running this script
# ------------------------------------------------------------------------------

# AD4134 data capture module
set ad4134_data_0 [create_bd_cell -type module -reference ad4134_data ad4134_data_0]

# ------------------------------------------------------------------------------
# Clock wizard for 50 MHz data capture clock (optional, can use sys_cpu_clk)
# If using sys_cpu_clk directly at 100 MHz, comment this out
# ------------------------------------------------------------------------------

ad_ip_instance clk_wiz clk_wiz_data
ad_ip_parameter clk_wiz_data CONFIG.PRIM_SOURCE Global_buffer
# Match clk_wiz input frequency to the actual sys_cpu_clk to avoid FREQ_HZ mismatch
set sys_cpu_clk_src_pin [lindex [get_bd_pins -of_objects $sys_cpu_clk -filter {DIR == O}] 0]
if {$sys_cpu_clk_src_pin eq ""} {
  set sys_cpu_clk_src_pin [lindex [get_bd_pins -of_objects $sys_cpu_clk] 0]
}
set sys_cpu_clk_freq_hz [get_property CONFIG.FREQ_HZ $sys_cpu_clk_src_pin]
set sys_cpu_clk_freq_mhz [format "%.6f" [expr {double($sys_cpu_clk_freq_hz) / 1000000.0}]]
ad_ip_parameter clk_wiz_data CONFIG.PRIM_IN_FREQ $sys_cpu_clk_freq_mhz
ad_ip_parameter clk_wiz_data CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 50.000
ad_ip_parameter clk_wiz_data CONFIG.USE_LOCKED false
ad_ip_parameter clk_wiz_data CONFIG.USE_RESET false

ad_connect $sys_cpu_clk clk_wiz_data/clk_in1

# Define the data capture clock (50 MHz from clock wizard)
set data_clk [get_bd_pins clk_wiz_data/clk_out1]

# ------------------------------------------------------------------------------
# Clock and Reset Connections
# ------------------------------------------------------------------------------

ad_connect $data_clk ad4134_data_0/clk
ad_connect sys_cpu_resetn ad4134_data_0/rst_n

# ------------------------------------------------------------------------------
# AD4134 Data Interface Connections (direct port-to-module)
# ------------------------------------------------------------------------------

ad_connect ad4134_din0 ad4134_data_0/data_in0
ad_connect ad4134_din1 ad4134_data_0/data_in1
ad_connect ad4134_din2 ad4134_data_0/data_in2
ad_connect ad4134_din3 ad4134_data_0/data_in3

# Output signals to AD4134
ad_connect ad4134_data_0/dclk_out ad4134_dclk
ad_connect ad4134_data_0/odr_out ad4134_odr

puts "=============================================================================="
puts "AD4134 Custom Data Capture Block Design Complete"
puts "=============================================================================="
puts "Data capture uses custom ad4134_data VHDL module"
puts "PS SPI0 EMIO is configured in zu_system_bd.tcl for register access"
puts "=============================================================================="

