#===========================================================
#-----------------FAILED EXCEPT IMEM PATHS------------------
#===========================================================


set all_failing [get_timing_paths -slack_lesser_than 0.5 -max_paths 50000 -nworst 1 -setup]

set non_decode_paths {}
foreach path $all_failing {
    set start [get_property STARTPOINT_PIN $path]
    set end   [get_property ENDPOINT_PIN $path]

    if {![string match -nocase "*imem_inst*" $start]} {
        lappend non_decode_paths $path
    }
}

if {[llength $non_decode_paths] > 0} {
    puts "Найдено путей вне стадии декодирования: [llength $non_decode_paths]"
    report_timing -of_objects $non_decode_paths -file non_decode_failing_paths.rpt
    report_timing -of_objects $non_decode_paths -name Non_Decode_Failing
} else {
    puts "Все пути с отрицательным слаком принадлежат исключительно стадии декодирования."
}

#===========================================================

set all_failing [get_timing_paths -slack_lesser_than 0.0 -max_paths 50000 -nworst 1 -setup]
set target_paths {}
foreach path $all_failing {
    set path_str [string tolower [report_timing -of_objects $path -return_string]]
    if {[string match "*imem_addr*" $path_str]} {
        lappend target_paths $path
    }
}

if {[llength $target_paths] > 0} {
    puts "Найдено путей: [llength $target_paths]"
    report_timing -of_objects $target_paths -file ex_critical_paths.rpt
    report_timing -of_objects $target_paths -name EX_Critical_Paths
} else {
    puts "Пути с указанными сигналами не найдены."
}

set target_paths {}
foreach path $all_failing {
    set path_str [string tolower [report_timing -of_objects $path -return_string]]
    if {[string match "*imem_addr*" $path_str]} {
        lappend target_paths $path
    }
}

foreach path $all_failing {
    set path_str [string tolower [report_timing -of_objects $path -return_string]]
    lappend target_paths $path
}

