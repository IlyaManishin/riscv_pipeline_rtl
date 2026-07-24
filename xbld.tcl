puts "=================== create prj ==================="

set enable_video 1
# if zero, video will be in 640x480
set video_320x240 1

set board_nexys_4 0
set board_basys_3 1

#---
set build_pll_ip  1
set build_imem_ip 0
set build_tdp_bram_ip 0 ; # TODO: supress warnings about AXI unconnected

set build_video_bram_ip $enable_video

#---
set prjName rv-nsu

if $board_basys_3 {
    set prjFPGA xc7a35tcpg236-1
}
if $board_nexys_4 {
    set prjFPGA xc7a100tcsg324-1
}

set current_dir [pwd]

set prjDir   "$current_dir"
set cfgDir   "$prjDir/cfg"
set constDir "$prjDir/src/constr"
set ipDir    "$prjDir/ip"
set rtlDir   "$prjDir/src/rtl"
set libDir   "$rtlDir/lib"
set simDir   "$prjDir/src/sim"
set vgaDir   "$libDir/vga/rtl"

#---
set tempDir "$prjDir/temp_cfg_backup"
file mkdir $tempDir
foreach f [glob -nocomplain $cfgDir/*.wcfg] {
    file copy -force $f $tempDir
}

#---
file delete -force $cfgDir
file mkdir $cfgDir
create_project $prjName $cfgDir -part $prjFPGA

set init_def_file [file join $cfgDir mem_init_path.svh]
set prgDir [file join $prjDir prg]

set fh [open $init_def_file w]
puts $fh "\`ifndef MEM_INIT_PATH_SVH"
puts $fh "\`define MEM_INIT_PATH_SVH"
puts $fh ""
puts $fh "//==== IMEM part"
puts $fh "// Available IMEM images - uncomment ONE to use:"

# Find all .mem files in prg directory and write commented defines
foreach memFile [glob -nocomplain [file join $prgDir *.mem]] {
    set memPathNormalized [file normalize $memFile]
    # Write commented define for easy switching between images
    puts $fh "//\`define IMEM_INIT_FILE \"$memPathNormalized\""
}

# Default IMEM and DMEM images if none selected above
puts $fh ""
puts $fh "// Default IMEM image (used if IMEM_INIT_FILE is not defined above)"
puts $fh "\`ifndef IMEM_INIT_FILE"
puts $fh "\`define IMEM_INIT_FILE \"[file normalize [file join $prgDir led_blink_kit.mem]]\""
puts $fh "\`endif  // IMEM_INIT_FILE"

puts $fh ""
puts $fh "//==== DMEM part"
puts $fh "\`define DMEM_INIT_FILE \"\""
puts $fh ""
puts $fh "\`endif  // MEM_INIT_PATH_SVH"
close $fh

puts "Generated IMEM init defines for all .mem files in $prgDir"

set video_config_file [file join $cfgDir video_config.svh]
set fh [open $video_config_file w]
if $enable_video {
    puts $fh "\`ifndef VIDEO_ENABLED"
    puts $fh "\`define VIDEO_ENABLED"
    puts $fh "\`endif"
}
puts $fh "\`ifndef VIDEO_HALF_RESOLUTION"
puts $fh "\`define VIDEO_HALF_RESOLUTION $video_320x240"
puts $fh "\`endif"
close $fh

add_files -fileset sources_1                     \
         $rtlDir/cpu_system.sv                   \
         $rtlDir/cpu_core.sv                     \
         $rtlDir/stages/fetch.sv                 \
         $rtlDir/stages/decode.sv                \
         $rtlDir/stages/execute.sv               \
         $rtlDir/stages/memory.sv                \
         $rtlDir/stages/writeback.sv             \
         $rtlDir/modules/hazard_detection_unit.sv\
         $rtlDir/modules/pc.sv                   \
         $rtlDir/modules/id.sv                   \
         $rtlDir/modules/branch_unit_m.sv        \
         $rtlDir/memory/imem.sv                  \
         $rtlDir/memory/risc_v_dmem_rd_port_m.sv \
         $rtlDir/memory/risc_v_dmem_wr_port_m.sv \
         $rtlDir/modules/imm_gen.sv              \
         $rtlDir/memory/register_file.sv         \
         $rtlDir/modules/alu.sv                  \
         $rtlDir/modules/shifter_alu.sv          \
         $rtlDir/uart_wrapper.sv                 \
         $rtlDir/lib/dual_port_mem.sv            \
         $libDir/rst_m.sv                        \
         $libDir/uart.sv                         \
         $vgaDir/sync_gen.sv                     \
         $vgaDir/syncer.sv                       \
         $vgaDir/vga.sv                          \
         $vgaDir/video_out.sv                    \
         $vgaDir/vram_reader.sv                  \
         $init_def_file

if $board_basys_3 {
    add_files -fileset constrs_1 \
            $constDir/rv_nsu_basys_3.xdc \
            $constDir/rv_nsu_basys_3.sdc
}

if $board_nexys_4 {
    add_files -fileset constrs_1 \
            $constDir/rv_nsu_nexys_4_ddr.xdc
}

add_files -fileset sim_1  \
         $simDir/rv_nsu_tb.sv

foreach f [glob -nocomplain $tempDir/*.wcfg] {
    set dest [file join $cfgDir [file tail $f]]
    file copy -force $f $dest
    add_files -fileset sim_1 $dest
}

file delete -force $tempDir

set_property INCLUDE_DIRS "$rtlDir $rtlDir/include $cfgDir" [get_filesets sources_1]
set_property INCLUDE_DIRS "$rtlDir $rtlDir/include $cfgDir" [get_filesets sim_1]
set_property used_in_synthesis      false [get_files  $simDir/rv_nsu_tb.sv]
set_property used_in_implementation false [get_files  $simDir/rv_nsu_tb.sv]
set_property top rv_nsu_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {1000us} -objects [get_filesets sim_1]

puts "=================== create IP's"

set_msg_config -suppress -id {Common 17-576}

#--- IP (pll)
if $build_pll_ip {
    puts "\n------------------- create PLL IP"
    set ip_pll_name   "pll"
    set ip_pll_clk    50.0

    if $enable_video {
        # lower frequency
        set ip_pll_clk    30.0
        # this will be rounded down to 25.0 MHz
        set ip_pll_video_clk 25.175
    }

    puts "\n------------------- Update TIME_BASE for UART"

    set time_base_ns [expr {int(1000.0 / $ip_pll_clk)}]

    if {$time_base_ns < 1.0} {
        puts "  WARNING: Clock frequency > 1000 MHz ($ip_pll_clk MHz)"
        puts "  TIME_BASE would be < 1 ns, using 1 ns"
        set time_base_value 1
    }

    puts "  PLL Clock: $ip_pll_clk MHz"
    puts "  TIME_BASE: $time_base_ns ns"

    set svh_file "$rtlDir/include/risc-v.svh"
    if {[file exists $svh_file]} {
        set fp [open $svh_file r]
        set content [read $fp]
        close $fp
    
        regsub -all {RV_TIME_BASE\s*=\s*\d+} $content "RV_TIME_BASE  = $time_base_ns" content
    
        set fp [open $svh_file w]
        puts $fp $content
        close $fp
    
        puts "  Updated $svh_file"
    } else {
        puts "  ERROR: $svh_file not found!"
    }

    file mkdir $ipDir
    set ip_pll_dir "$ipDir/$ip_pll_name"
    file delete -force $ip_pll_dir

    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name $ip_pll_name -dir $ipDir
    set_property -dict [ \
                        list CONFIG.Component_Name $ip_pll_name        \
                        CONFIG.PRIMITIVE {PLL}                         \
                        CONFIG.PRIMARY_PORT {clk_in}                   \
                        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $ip_pll_clk  \
                        CONFIG.USE_RESET {false}                       \
                        ] [get_ips $ip_pll_name]

    if $enable_video {
        set_property -dict [ \
                        list                                                 \
                        CONFIG.CLKOUT2_USED {true}                           \
                        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $ip_pll_video_clk  \
                        CONFIG.CLKOUT2_REQUESTED_PHASE 0                     \
                        CONFIG.CLK_OUT2_PORT {clk_video}                     \
                        ] [get_ips $ip_pll_name]
    }

    generate_target {instantiation_template} [get_files $ip_pll_dir/$ip_pll_name.xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_pll_dir/$ip_pll_name.xci]
    catch { config_ip_cache -export [get_ips -all $ip_pll_name] }
    export_ip_user_files -of_objects [get_files $ip_pll_dir/$ip_pll_name.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_pll_dir/$ip_pll_name.xci]

    #---
    launch_runs -jobs 4 ${ip_pll_name}_synth_1
    wait_on_run ${ip_pll_name}_synth_1
}

#--- IP (Simple Dual-Port Block RAM)
if $build_imem_ip {
    puts "\n------------------- create Simple_Dual_Port_RAM IP"
    set ip_imem_name "blk_mem_sdp"
    set bitWidth 32
    set memDepth 1024

    file mkdir $ipDir
    set ip_imem_dir "$ipDir/$ip_imem_name"
    file delete -force $ip_imem_dir

    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_imem_name -dir $ipDir
    set_property -dict [ \
        list CONFIG.Component_Name {blk_mem_sdp}   \
        CONFIG.Memory_Type {Simple_Dual_Port_RAM}  \
        CONFIG.Assume_Synchronous_Clk {true}       \
        CONFIG.Write_Width_A $bitWidth             \
        CONFIG.Write_Depth_A $memDepth             \
        CONFIG.Read_Width_A  $bitWidth             \
        CONFIG.Operating_Mode_A {READ_FIRST}       \
        CONFIG.Write_Width_B $bitWidth             \
        CONFIG.Read_Width_B $bitWidth              \
        CONFIG.Operating_Mode_B {READ_FIRST}       \
        CONFIG.Enable_B {Use_ENB_Pin}              \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
        CONFIG.Load_Init_File {false} \
        CONFIG.Fill_Remaining_Memory_Locations {true} \
        CONFIG.Remaining_Memory_Locations {800000ec} \
        CONFIG.Port_B_Clock {100} \
        CONFIG.Port_B_Enable_Rate {100} \
        ] [get_ips $ip_imem_name]

    generate_target {instantiation_template} [get_files $ip_imem_dir/$ip_imem_name.xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_imem_dir/$ip_imem_name.xci]
    catch { config_ip_cache -export [get_ips -all $ip_imem_name] }
    export_ip_user_files -of_objects [get_files $ip_imem_dir/$ip_imem_name.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_imem_dir/$ip_imem_name.xci]

    #---
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_output_block}
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_gen_prim_wrapper_init}
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_gen_generic_cstr}
    set_msg_config -suppress -id {Synth 8-3331} -string {blk_mem_input_block}

    #---
    launch_runs ${ip_imem_name}_synth_1 -jobs 4
    wait_on_run ${ip_imem_name}_synth_1

    #---
    reset_msg_config -suppress -id {Synth 8-3331}
}

#--- IP (True Dual-Port Block RAM)
if $build_tdp_bram_ip {
    puts "\n------------------- create True_Dual_Port_RAM IP"
    set ip_imem_name "tdp_bram_ip"
    set bitWidth 32
    set byteSize 8
    set memDepth 1024

    file mkdir $ipDir
    set ip_imem_dir "$ipDir/$ip_imem_name"
    file delete -force $ip_imem_dir

    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_imem_name -dir $ipDir
    set_property -dict [ \
        list CONFIG.Component_Name {tdp_bram_ip}                  \
        CONFIG.Memory_Type {True_Dual_Port_RAM}                   \
        CONFIG.Use_Byte_Write_Enable {true}                       \
        CONFIG.Byte_Size     $byteSize                            \
        CONFIG.Write_Width_A $bitWidth                            \
        CONFIG.Write_Depth_A $memDepth                            \
        CONFIG.Read_Width_A  $bitWidth                            \
        CONFIG.Operating_Mode_A {READ_FIRST}                      \
        CONFIG.Enable_A {Use_ENA_Pin}                             \
        CONFIG.Write_Width_B $bitWidth                            \
        CONFIG.Read_Width_B $bitWidth                             \
        CONFIG.Operating_Mode_B {READ_FIRST}                      \
        CONFIG.Enable_B {Use_ENB_Pin}                             \
        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
        CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
        CONFIG.Fill_Remaining_Memory_Locations {true}             \
        CONFIG.Port_B_Clock {100}                                 \
        CONFIG.Port_B_Write_Rate {50}                             \
        CONFIG.Port_B_Enable_Rate {100}                           \
    ] [get_ips $ip_imem_name]

    generate_target {instantiation_template} [get_files $ip_imem_dir/$ip_imem_name.xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_imem_dir/$ip_imem_name.xci]
    catch { config_ip_cache -export [get_ips -all $ip_imem_name] }
    export_ip_user_files -of_objects [get_files $ip_imem_dir/$ip_imem_name.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_imem_dir/$ip_imem_name.xci]

    #---
    set_msg_config -suppress -id {Synth 8-3331}
    launch_runs ${ip_imem_name}_synth_1 -jobs 4
    wait_on_run ${ip_imem_name}_synth_1

    reset_msg_config -suppress -id {Synth 8-3331}
}    

if $build_video_bram_ip {
    set ip_video_bram_name "video_pixel_bram"

    file mkdir $ipDir
    set ip_video_bram_dir "$ipDir/$ip_video_bram_name"
    file delete -force "$ip_video_bram_dir"

    set ip_video_bram_xci "$ip_video_bram_dir/$ip_video_bram_name.xci"

    if $video_320x240 {
        set ip_video_bram_write_depth_a [expr 320*240/4]
    } else {
        set ip_video_bram_write_depth_a [expr 640*480/4]
    }

    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ip_video_bram_name -dir $ipDir
    set_property -dict [list \
        CONFIG.Byte_Size {8} \
        CONFIG.Use_Byte_Write_Enable {true} \
        CONFIG.Enable_B {Always_Enabled} \
        CONFIG.Load_Init_File {false} \
        CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
        CONFIG.Write_Depth_A $ip_video_bram_write_depth_a \
        CONFIG.Write_Width_A {32} \
        CONFIG.Write_Width_B {8} \
        CONFIG.Operating_Mode_A {WRITE_FIRST} \
        CONFIG.Assume_Synchronous_Clk {true} \
    ] [get_ips $ip_video_bram_name]
    generate_target {instantiation_template} [get_files $ip_video_bram_xci]
    update_compile_order -fileset sources_1
    generate_target all [get_files  $ip_video_bram_xci]

    catch { config_ip_cache -export [get_ips -all $ip_video_bram_name] }
    export_ip_user_files -of_objects [get_files $ip_video_bram_xci] -no_script -sync -force -quiet

    create_ip_run [get_files -of_objects [get_fileset sources_1] $ip_video_bram_xci]

    launch_runs ${ip_video_bram_name}_synth_1 -jobs 16
    wait_on_run ${ip_video_bram_name}_synth_1
}