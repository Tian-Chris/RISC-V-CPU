# runwith source "U:/Documents/RISC-V CPU/Risc.srcs/sources_1/new/tests/run_testbench.tcl"
# Get the directory where this script is located
set script_dir [file dirname [info script]]

# Change to XSIM directory to run the simulator
cd "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim"

# Get list of .hex files in the script's directory
set hex_files [glob -nocomplain "$script_dir/*.hex"]
array set results {}
array set reasons {}

if {[llength $hex_files] == 0} {
    puts "No .hex files found in $script_dir"
    return
}

foreach file $hex_files {
    set testname [file rootname [file tail $file]]
    puts "\nRunning test: $testname"

    # Copy the .hex file into test/test.mem
    file copy -force $file "test/test.mem"

    # Run the simulation
    set sim_cmd "xsim cpu_top_tb_behav -runall"
    puts "Executing: $sim_cmd"
    set sim_output [exec {*}$sim_cmd]

    # Determine result from output
    if {[string first "TEST PASSED" $sim_output] >= 0} {
        set results($testname) "PASS"
        set reasons($testname) ""
    } elseif {[string first "TIMEOUT" $sim_output] >= 0} {
        set results($testname) "FAIL"
        set reasons($testname) "TIMED OUT"
    } elseif {[string first "TEST FAILED" $sim_output] >= 0} {
        set results($testname) "FAIL"
        # Try to extract gp value
        set match [regexp {gp \(x3\) = ([0-9]+) \(0x([0-9a-fA-F]+)\)} $sim_output -> gp_dec gp_hex]
        if {$match} {
            set reasons($testname) "gp = $gp_dec (0x$gp_hex)"
        } else {
            set reasons($testname) "TEST FAILED (gp value not found)"
        }
    } else {
        set results($testname) "UNKNOWN"
        set reasons($testname) "Output did not contain recognizable result"
    }
}

# Print summary
puts "\n=== TEST SUMMARY ==="
foreach testname [lsort [array names results]] {
    set result $results($testname)
    if {[info exists reasons($testname)]} {
        set reason $reasons($testname)
    } else {
        set reason "No reason recorded"
    }

    if {$result eq "PASS"} {
        puts "Test $testname : PASS"
    } else {
        puts "Test $testname : FAIL - $reason"
    }
}
