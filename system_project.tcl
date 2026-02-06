###############################################################################
## Copyright (C) 2023 Analog Devices, Inc. All rights reserved.
## Modified for custom data capture (replacing SPI Engine)
### SPDX short identifier: ADIBSD
###############################################################################

source ../../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl
source $ad_hdl_dir/projects/ad4134_fmc/tq15eg/tq15eg_2023_1.tcl

# Set path to custom VHDL sources (local copies with fixes for combined design)
set custom_src_dir "$ad_hdl_dir/projects/ad4134_fmc/tq15eg_data/"

# Create project with custom suffix
set project_name "ad4134_fmc_tq15eg"

adi_project $project_name

# Add custom VHDL sources BEFORE creating block design
# These must be added first so module references work
add_files -norecurse [list \
    "$custom_src_dir/ad4134_data.vhd" \
    "$custom_src_dir/ad4134_axis_packer.vhd"]

update_compile_order -fileset sources_1

# Add project files
adi_project_files $project_name [list \
    "$ad_hdl_dir/library/common/ad_iobuf.v" \
    "system_top.v" \
    "system_constr.xdc" ]

# Note: The block design is created from system_bd.tcl
# To use custom BD, rename system_bd_custom.tcl to system_bd.tcl
# Or modify system_bd.tcl to source ad4134_bd_custom.tcl

adi_project_run $project_name

