# runwith source "U:/Documents/RISC-V CPU/Risc.srcs/sources_1/new/run_testbench.tcl"
cd "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim"

set runs [list "add" "sub" "and" "or" "xor" "sll" "srl" "sra" "slt" "imm" "memory" "control" "jump" "other"]
array set results {}

foreach r $runs {
    puts "\nRunning test: $r"

    file copy -force "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/runs/$r/result.golden" "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test.golden"
    file copy -force "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/runs/$r/instr.mem" "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/test/test.mem"

    set sim_cmd "xsim cpu_top_tb_behav -runall"
    puts "Executing: $sim_cmd"
    set sim_output [exec {*}$sim_cmd]

    # Determine pass/fail from sim_output
    if {[string first "PASSED" $sim_output] >= 0} {
        set results($r) "PASS"
    } elseif {[string first "FAILED" $sim_output] >= 0} {
        set results($r) "FAIL"
    } else {
        set results($r) "UNKNOWN"
    }
}

puts "\n=== TEST SUMMARY ==="
foreach r $runs {
    puts "Test $r : $results($r)"
}
