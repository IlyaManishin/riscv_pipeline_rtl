puts "=================== create prj"

set build_video_bram_ip 1
set build_clock_gen_ip  1

set prjName rv-vga
set prjFPGA xc7a100tcsg324-1


set current_dir [pwd]
set prjDir   "$current_dir"
set cfgDir   "$prjDir/vivado_cfg"
set constDir "$prjDir/constraints"
set ipDir    "$prjDir/ip"
set rtlDir   "$prjDir/rtl"
set simDir   "$prjDir/sim"

# backup waveform configs
set tempDir "$prjDir/temp_cfg_backup"
file mkdir $tempDir
foreach f [glob -nocomplain $cfgDir/*.wcfg] {
    file copy -force $f $tempDir
}

# (re)create project
file delete -force $cfgDir
file mkdir $cfgDir
create_project $prjName $cfgDir -part $prjFPGA

# TODO: memory initialization


add_files -fileset sources_1        \
         $rtlDir/video_out.sv \
         $rtlDir/sync_gen.sv \
         $rtlDir/nexys_4_ddr_top.sv \
         $rtlDir/syncer.sv \
         $rtlDir/vram_reader.sv \
         $rtlDir/vga.sv

add_files -fileset constrs_1 \
         $constDir/Nexys-4-DDR-Master.xdc

add_files -fileset sim_1  \
         $simDir/video_out_static_color_tb.sv \
         $simDir/fifo_image_tb.sv \
         $simDir/bram_image_tb.sv \

set_property INCLUDE_DIRS "$rtlDir $cfgDir" [get_filesets sim_1]
set_property used_in_synthesis      false [get_files  $simDir/video_out_static_color_tb.sv]
set_property used_in_implementation false [get_files  $simDir/video_out_static_color_tb.sv]
set_property used_in_synthesis      false [get_files  $simDir/fifo_image_tb.sv]
set_property used_in_implementation false [get_files  $simDir/fifo_image_tb.sv]
set_property used_in_synthesis      false [get_files  $simDir/bram_image_tb.sv]
set_property used_in_implementation false [get_files  $simDir/bram_image_tb.sv]
set_property top bram_image_tb [get_filesets sim_1]
# set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]


# restore waveform configs
foreach f [glob -nocomplain $tempDir/*.wcfg] {
    set dest [file join $cfgDir [file tail $f]]
    file copy -force $f $dest
    add_files -fileset sim_1 $dest
}
file delete -force $tempDir

if $build_video_bram_ip {
    set ip_video_bram_name "video_pixel_bram"

    file mkdir $ipDir
    set ip_video_bram_dir "$ipDir/$ip_video_bram_name"
    file delete -force "$ip_video_bram_dir"

    set ip_video_bram_xci "$ip_video_bram_dir/$ip_video_bram_name.xci"

    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_video_bram_name -dir $ipDir
    set_property -dict [list \
        CONFIG.Coe_File $prjDir/py_verify/test_patterns/checkerboard_320x240.png.coe  \
        CONFIG.Enable_B {Always_Enabled} \
        CONFIG.Load_Init_File {true} \
        CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
        CONFIG.Write_Depth_A {76800} \
        CONFIG.Write_Width_A {32} \
        CONFIG.Write_Width_B {8} \
    ] [get_ips $ip_video_bram_name]
    generate_target {instantiation_template} [get_files $ip_video_bram_xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_video_bram_xci]

    catch { config_ip_cache -export [get_ips -all $ip_video_bram_name] }
    export_ip_user_files -of_objects [get_files $ip_video_bram_xci] -no_script -sync -force -quiet
    # export_simulation -of_objects [get_files /home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci] -directory /home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.ip_user_files/sim_scripts -ip_user_files_dir /home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.ip_user_files -ipstatic_source_dir /home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.ip_user_files/ipstatic -lib_map_path [list {modelsim=/home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.cache/compile_simlib/modelsim} {questa=/home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.cache/compile_simlib/questa} {xcelium=/home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.cache/compile_simlib/xcelium} {vcs=/home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.cache/compile_simlib/vcs} {riviera=/home/ilya/work/fpga/rv_vga_dirs/riscv_vga/vivado_cfg/rv-vga.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_video_bram_xci]

    launch_runs ${ip_video_bram_name}_synth_1 -jobs 16
    wait_on_run ${ip_video_bram_name}_synth_1
}

if $build_clock_gen_ip {
    set ip_clock_gen_name "clock_gen"

    file mkdir $ipDir
    set ip_clock_gen_dir "$ipDir/$ip_clock_gen_name"
    file delete -force "$ip_clock_gen_dir"

    set ip_clock_gen_xci "$ip_clock_gen_dir/$ip_clock_gen_name.xci"


    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name $ip_clock_gen_name -dir $ipDir
    set_property -dict [list \
        CONFIG.CLKOUT1_DRIVES {BUFG} \
        CONFIG.CLKOUT1_JITTER {319.783} \
        CONFIG.CLKOUT1_PHASE_ERROR {246.739} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.175} \
        CONFIG.CLKOUT2_DRIVES {BUFG} \
        CONFIG.CLKOUT3_DRIVES {BUFG} \
        CONFIG.CLKOUT4_DRIVES {BUFG} \
        CONFIG.CLKOUT5_DRIVES {BUFG} \
        CONFIG.CLKOUT6_DRIVES {BUFG} \
        CONFIG.CLKOUT7_DRIVES {BUFG} \
        CONFIG.ENABLE_CLOCK_MONITOR {false} \
        CONFIG.MMCM_CLKFBOUT_MULT_F {36.375} \
        CONFIG.MMCM_CLKOUT0_DIVIDE_F {36.125} \
        CONFIG.MMCM_DIVCLK_DIVIDE {4} \
        CONFIG.PRIMITIVE {MMCM} \
        CONFIG.PRIM_SOURCE {Global_buffer} \
        CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
        CONFIG.USE_PHASE_ALIGNMENT {true} \
        CONFIG.USE_RESET {false} \
    ] [get_ips $ip_clock_gen_name]
    generate_target {instantiation_template} [get_files $ip_clock_gen_xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_clock_gen_xci]

    catch { config_ip_cache -export [get_ips -all $ip_clock_gen_name] }
    export_ip_user_files -of_objects [get_files $ip_clock_gen_xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_clock_gen_xci]

    launch_runs ${ip_clock_gen_name}_synth_1 -jobs 16
    wait_on_run ${ip_clock_gen_name}_synth_1
}