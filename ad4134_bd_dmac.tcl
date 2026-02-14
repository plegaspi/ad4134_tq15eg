###############################################################################
## Copyright (C) 2023-2024 Analog Devices, Inc. All rights reserved.
## Modified for custom data capture with AXI DMAC output
### SPDX short identifier: ADIBSD
###############################################################################

# ==============================================================================
# AD4134 Custom Data Capture Block Design (AXI DMAC)
# Replaces BRAM writer with AXI-Stream -> AXI DMAC -> DDR
# Keeps PS SPI0 EMIO for register configuration (configured in zu_system_bd.tcl)
# ==============================================================================

# ------------------------------------------------------------------------------
# Create external ports for AD4134 data interface
# ------------------------------------------------------------------------------

create_bd_port -dir I ad4134_din0
create_bd_port -dir I ad4134_din1
create_bd_port -dir I ad4134_din2
create_bd_port -dir I ad4134_din3
create_bd_port -dir O ad4134_dclk
create_bd_port -dir O ad4134_odr



# ------------------------------------------------------------------------------
# Create external ports for AD7134 data interface
# ------------------------------------------------------------------------------

create_bd_port -dir I ad7134_din0
create_bd_port -dir I ad7134_din1
create_bd_port -dir I ad7134_din2
create_bd_port -dir I ad7134_din3
create_bd_port -dir I ad7134_din4
create_bd_port -dir I ad7134_din5
create_bd_port -dir I ad7134_din6
create_bd_port -dir I ad7134_din7
create_bd_port -dir O ad7134_dclk
create_bd_port -dir O ad7134_odr


# ------------------------------------------------------------------------------
# Custom VHDL Modules
# ------------------------------------------------------------------------------

set ad4134_data_0 [create_bd_cell -type module -reference ad4134_data ad4134_data_0]
set ad4134_axis_0 [create_bd_cell -type module -reference ad4134_axis_packer ad4134_axis_0]

set ad7134_data_0 [create_bd_cell -type module -reference ad4134_data ad7134_data_0]


# ------------------------------------------------------------------------------
# Clock wizard for 50 MHz data capture clock (optional, can use sys_cpu_clk)
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
ad_ip_parameter clk_wiz_data CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 75.000
ad_ip_parameter clk_wiz_data CONFIG.USE_LOCKED false
ad_ip_parameter clk_wiz_data CONFIG.USE_RESET false

ad_connect $sys_cpu_clk clk_wiz_data/clk_in1

set data_clk [get_bd_pins clk_wiz_data/clk_out1]

# ------------------------------------------------------------------------------
# AXI DMAC (stream -> DDR)
# ------------------------------------------------------------------------------

ad_ip_instance axi_dmac axi_ad4134_dma
ad_ip_parameter axi_ad4134_dma CONFIG.DMA_TYPE_SRC 1
ad_ip_parameter axi_ad4134_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter axi_ad4134_dma CONFIG.CYCLIC 0
ad_ip_parameter axi_ad4134_dma CONFIG.SYNC_TRANSFER_START 0
ad_ip_parameter axi_ad4134_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter axi_ad4134_dma CONFIG.DMA_DATA_WIDTH_SRC 256
ad_ip_parameter axi_ad4134_dma CONFIG.DMA_DATA_WIDTH_DEST 64

# ------------------------------------------------------------------------------
# AXIS FIFO (buffers samples during DMA re-arm gap)
# 1024 entries x 128 bit = 16 KB; covers re-arm latency at ~161 kHz
# ------------------------------------------------------------------------------

ad_ip_instance util_axis_fifo axis_fifo_0
ad_ip_parameter axis_fifo_0 CONFIG.DATA_WIDTH 256
ad_ip_parameter axis_fifo_0 CONFIG.ADDRESS_WIDTH 12
ad_ip_parameter axis_fifo_0 CONFIG.ASYNC_CLK 0

# ------------------------------------------------------------------------------
# Clock and Reset Connections
# ------------------------------------------------------------------------------

ad_connect $data_clk ad4134_data_0/clk
ad_connect $data_clk ad7134_data_0/clk
ad_connect $data_clk ad4134_axis_0/clk

ad_connect sys_cpu_resetn ad4134_data_0/rst_n
ad_connect sys_cpu_resetn ad7134_data_0/rst_n
ad_connect sys_cpu_resetn ad4134_axis_0/rst_n

ad_connect $data_clk axis_fifo_0/s_axis_aclk
ad_connect $data_clk axis_fifo_0/m_axis_aclk
ad_connect sys_cpu_resetn axis_fifo_0/s_axis_aresetn
ad_connect sys_cpu_resetn axis_fifo_0/m_axis_aresetn

ad_connect $data_clk axi_ad4134_dma/s_axis_aclk
ad_connect $sys_dma_clk axi_ad4134_dma/m_dest_axi_aclk
ad_connect $sys_dma_resetn axi_ad4134_dma/m_dest_axi_aresetn

# ------------------------------------------------------------------------------
# AD4134 Data Interface Connections (direct port-to-module)
# ------------------------------------------------------------------------------

ad_connect ad4134_din0 ad4134_data_0/data_in0
ad_connect ad4134_din1 ad4134_data_0/data_in1
ad_connect ad4134_din2 ad4134_data_0/data_in2
ad_connect ad4134_din3 ad4134_data_0/data_in3

ad_connect ad7134_din0 ad7134_data_0/data_in0
ad_connect ad7134_din1 ad7134_data_0/data_in1
ad_connect ad7134_din4 ad7134_data_0/data_in2
ad_connect ad7134_din5 ad7134_data_0/data_in3

ad_connect ad4134_data_0/dclk_out ad4134_dclk
ad_connect ad4134_data_0/odr_out ad4134_odr

ad_connect ad7134_data_0/dclk_out ad7134_dclk
ad_connect ad7134_data_0/odr_out ad7134_odr

# ------------------------------------------------------------------------------
# Data flow: ad4134_data -> AXIS packer -> AXIS FIFO -> AXI DMAC
# ------------------------------------------------------------------------------

ad_connect ad4134_data_0/data_out0 ad4134_axis_0/data_in0
ad_connect ad4134_data_0/data_out1 ad4134_axis_0/data_in1
ad_connect ad4134_data_0/data_out2 ad4134_axis_0/data_in2
ad_connect ad4134_data_0/data_out3 ad4134_axis_0/data_in3

ad_connect ad7134_data_0/data_out0 ad4134_axis_0/data_in4
ad_connect ad7134_data_0/data_out1 ad4134_axis_0/data_in5
ad_connect ad7134_data_0/data_out2 ad4134_axis_0/data_in6
ad_connect ad7134_data_0/data_out3 ad4134_axis_0/data_in7

ad_connect ad4134_data_0/data_rdy  ad4134_axis_0/data_rdy

# Packer -> FIFO (tlast not connected: TLAST_EN=0 on FIFO, always 0 anyway)
ad_connect ad4134_axis_0/m_axis_tdata  axis_fifo_0/s_axis_data
ad_connect ad4134_axis_0/m_axis_tvalid axis_fifo_0/s_axis_valid
ad_connect axis_fifo_0/s_axis_ready    ad4134_axis_0/m_axis_tready

# FIFO -> DMAC
ad_connect axis_fifo_0/m_axis_data  axi_ad4134_dma/s_axis_data
ad_connect axis_fifo_0/m_axis_valid axi_ad4134_dma/s_axis_valid
ad_connect axi_ad4134_dma/s_axis_ready axis_fifo_0/m_axis_ready

# Tie off AXIS sideband signals
# last = 0 (DMAC completes on X_LENGTH, not tlast)
ad_connect GND axi_ad4134_dma/s_axis_last
# strb/keep = all ones (all bytes valid in 128-bit word)
ad_ip_instance xlconstant const_axis_strb
ad_ip_parameter const_axis_strb CONFIG.CONST_WIDTH 32
ad_ip_parameter const_axis_strb CONFIG.CONST_VAL 0xFFFFFFFF
ad_connect const_axis_strb/dout axi_ad4134_dma/s_axis_strb
ad_connect const_axis_strb/dout axi_ad4134_dma/s_axis_keep

# user/id/dest = 0 (unused optional signals)
ad_connect GND axi_ad4134_dma/s_axis_user
ad_connect GND axi_ad4134_dma/s_axis_id
ad_connect GND axi_ad4134_dma/s_axis_dest

# ------------------------------------------------------------------------------
# AXI Address Assignments
# ------------------------------------------------------------------------------

ad_cpu_interconnect 0x44a30000 axi_ad4134_dma

# Note: Not using interrupts - software polls TRANSFER_DONE register instead

# ------------------------------------------------------------------------------
# Memory interconnect (HP0 for DMA to DDR)
# For ZynqMP, must first enable HP0 on PS8, then add DMA master
# ------------------------------------------------------------------------------

# Enable HP0 slave port on PS8 (S_AXI_HP0_FPD)
ad_ip_parameter sys_ps8 CONFIG.PSU__USE__S_AXI_GP2 1

# First call creates the interconnect and connects to PS HP0
ad_mem_hp0_interconnect $sys_dma_clk sys_ps8/S_AXI_HP0_FPD

# Second call adds the DMA master to the interconnect
ad_mem_hp0_interconnect $sys_dma_clk axi_ad4134_dma/m_dest_axi

puts "=============================================================================="
puts "AD4134 AXI DMAC Block Design Complete"
puts "=============================================================================="

