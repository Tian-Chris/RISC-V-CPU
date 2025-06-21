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

# Helper to run a batch of up to 5 test files
proc run_batch {batch} {
    global sim_dir results failure_reasons

    # Copy each file into test1.mem to test5.mem
    set index 1
    foreach file $batch {
        set target_file "$sim_dir/test/test${index}.mem"
        file copy -force $file $target_file
        incr index
    }

    # Clear out unused testN.mem slots
    while {$index <= 5} {
        set target_file "$sim_dir/test/test${index}.mem"
        if {[file exists $target_file]} {
            file delete -force $target_file
        }
        incr index
    }

    # Run simulation
    puts "\nINFO: Running simulation for batch:"
    foreach f $batch {
        puts "  [file tail $f]"
    }

    # Run the simulation and capture output
    set output ""
    set code [catch {set output [exec xsim cpu_top_tb_behav -runall]} err]

    if {$code != 0} {
        puts "ERROR: Simulation failed with error:"
        puts $err
        foreach f $batch {
            set results([file tail $f]) "SIM ERROR"
            set failure_reasons([file tail $f]) ""
        }
        return
    }

    # Parse simulation output for test results and reasons
    set lines [split $output "\n"]
    array set results_batch {}

    foreach line $lines {
        # Match lines like: [TEST 1 PASSED], [TEST 4 FAILED reason], or [TEST 3 TIMEOUT]
        if {[regexp {\[TEST (\d+) PASSED\]} $line -> testnum]} {
            set results_batch($testnum) "PASS"
            set failure_reasons($testnum) ""
        } elseif {[regexp {\[TEST (\d+) FAILED\](.*)} $line -> testnum reason_part]} {
            set results_batch($testnum) "FAIL"
            set failure_reasons($testnum) [string trim $reason_part]
        } elseif {[regexp {\[TEST (\d+) TIMEOUT\]} $line -> testnum]} {
            set results_batch($testnum) "TIMEOUT"
            set failure_reasons($testnum) ""
        }
    }

    # Map batch files (by order) to these results
    set index 1
    foreach file $batch {
        set fname [file tail $file]
        if {[info exists results_batch($index)]} {
            set results($fname) $results_batch($index)
            if {$results_batch($index) eq "FAIL"} {
                set failure_reasons($fname) $failure_reasons($index)
            } else {
                set failure_reasons($fname) ""
            }
        } else {
            set results($fname) "UNKNOWN"
            set failure_reasons($fname) ""
        }
        incr index
    }

    # Print summary for this batch only
    puts "\nINFO: Batch results:"
    foreach f $batch {
        set fname [file tail $f]
        puts "  $fname : $results($fname)"
        if {$results($fname) eq "FAIL" && $failure_reasons($fname) ne ""} {
            puts "$failure_reasons($fname)"
        }
    }
}

# Loop over tests in batches of 5
set i 0
while {$i < $total_tests} {
    # Select up to 5 files starting at index i
    set batch [lrange $mem_files $i [expr {$i + 4}]]
    run_batch $batch
    incr i 5
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
