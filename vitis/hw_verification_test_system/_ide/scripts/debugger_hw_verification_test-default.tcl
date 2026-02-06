# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/neutrino/work/AD4134_git/vitis/hw_verification_test_system/_ide/scripts/debugger_hw_verification_test-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source /home/neutrino/work/AD4134_git/vitis/hw_verification_test_system/_ide/scripts/debugger_hw_verification_test-default.tcl
# 
connect -url tcp:127.0.0.1:3121
source /tools/Xilinx/Vitis/2023.1/scripts/vitis/util/zynqmp_utils.tcl
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT1 210203859146A" && level==0 && jtag_device_ctx=="jsn-JTAG-SMT1-210203859146A-14750093-0"}
fpga -file /home/neutrino/work/AD4134_git/vitis/hw_verification_test/_ide/bitstream/system_top.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw /home/neutrino/work/AD4134_git/vitis/tq15eg_combine_rtos/export/tq15eg_combine_rtos/hw/system_top.xsa -mem-ranges [list {0x80000000 0xbfffffff} {0x400000000 0x5ffffffff} {0x1000000000 0x7fffffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
set mode [expr [mrd -value 0xFF5E0200] & 0xf]
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow /home/neutrino/work/AD4134_git/vitis/tq15eg_combine_rtos/export/tq15eg_combine_rtos/sw/tq15eg_combine_rtos/boot/fsbl.elf
set bp_42_46_fsbl_bp [bpadd -addr &XFsbl_Exit]
con -block -timeout 60
bpremove $bp_42_46_fsbl_bp
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow /home/neutrino/work/AD4134_git/vitis/hw_verification_test/Debug/hw_verification_test.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A53*#0"}
con
