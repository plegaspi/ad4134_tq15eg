# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/neutrino/work/AD4134_git/vitis/tq15eg_combine_rtos/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/neutrino/work/AD4134_git/vitis/tq15eg_combine_rtos/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {tq15eg_combine_rtos}\
-hw {/home/neutrino/Documents/hdl-2022_r2_p1/projects/ad4134_fmc/tq15eg_data/system_top.xsa}\
-proc {psu_cortexa53_0} -os {freertos10_xilinx} -arch {64-bit} -fsbl-target {psu_cortexa53_0} -out {/home/neutrino/work/AD4134_git/vitis}

platform write
platform generate -domains 
platform active {tq15eg_combine_rtos}
bsp reload
bsp setlib -name lwip213 -ver 1.0
bsp config api_mode "SOCKET_API"
bsp write
bsp reload
catch {bsp regenerate}
platform generate
platform active {tq15eg_combine_rtos}
bsp reload
bsp config phy_link_speed "CONFIG_LINKSPEED_AUTODETECT"
bsp config phy_link_speed "CONFIG_LINKSPEED1000"
bsp write
bsp reload
catch {bsp regenerate}
platform generate -domains freertos10_xilinx_domain 
platform generate
