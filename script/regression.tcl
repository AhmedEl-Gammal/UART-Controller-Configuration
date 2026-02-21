#######################################################################
########  Test List   
#######################################################################

set test_list { "reset_default_test_w" "reset_default_test_r"  "shadow_state_test" \
                "sticky_bit_test" "write_negtive_test" "write_read_hazard_test" \
			    "write_read_oob_test" "write_read_operation_test" "write_reserved_register"
			  }

#######################################################################
########  Handle File  
#######################################################################			   
set summary "./results/regression_summary.txt"
set fp [open $summary "w"]

puts $fp "======================================"
puts $fp "Regression Summary"
puts $fp "======================================"
#######################################################################
########  Run Regression for each Test    
#######################################################################
foreach test $test_list {
    puts $fp "Running ...$test"
	set testname $test
	puts $fp "$test: Done log in ./results/${test}.log"
	do ./scripts/run_test.tcl 
}
close $fp 

