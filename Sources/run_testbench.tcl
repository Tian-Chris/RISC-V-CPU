# runwith source "U:/Documents/RISC-V CPU/Risc.srcs/sources_1/new/run_testbench.tcl"

# Define paths
set test_source_dir "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim/tests"
set sim_dir "U:/Documents/RISC-V CPU/Risc.sim/sim_1/behav/xsim"
cd $sim_dir

# Collect all test hex files
set mem_files [glob -directory $test_source_dir *.hex]
set total_tests [llength $mem_files]
puts "Found $total_tests test(s)."

# Initialize test results and failure reasons
array set results {}
array set failure_reasons {}

# Run one test at a time
foreach file $mem_files {
    set fname [file tail $file]
    puts "\nINFO: Running simulation for $fname"

    # Copy to test1.mem
    file copy -force $file "$sim_dir/test/test1.mem"

    # Remove other testN.mem files just in case
    for {set n 2} {$n <= 10} {incr n} {
        set tfile "$sim_dir/test/test${n}.mem"
        if {[file exists $tfile]} {
            file delete -force $tfile
        }
    }

    # Run simulation and capture output
    set output ""
    set code [catch {set output [exec xsim cpu_top_tb_behav -runall]} err]

    if {$code != 0} {
        puts "ERROR: Simulation failed for $fname:"
        puts $err
        set results($fname) "SIM ERROR"
        set failure_reasons($fname) ""
        continue
    }

    # Parse output
    set lines [split $output "\n"]
    set status "UNKNOWN"
    set reason ""

    foreach line $lines {
        if {[regexp {\[TEST 1 PASSED\]} $line]} {
            set status "PASS"
        } elseif {[regexp {\[TEST 1 FAILED\](.*)} $line -> reason_part]} {
            set status "FAIL"
            set reason [string trim $reason_part]
        } elseif {[regexp {\[TEST 1 TIMEOUT\]} $line]} {
            set status "TIMEOUT"
        }
    }

    set results($fname) $status
    set failure_reasons($fname) $reason

    puts "  Result: $status"
    if {$status eq "FAIL" && $reason ne ""} {
        puts "  Reason: $reason"
    }
}

# Final summary
puts "\n=== FINAL TEST SUMMARY ==="
foreach f [lsort [array names results]] {
    if {$results($f) eq "FAIL" && $failure_reasons($f) ne ""} {
        puts "Test $f : $results($f) - Reason: $failure_reasons($f)"
    } else {
        puts "Test $f : $results($f)"
    }
}
