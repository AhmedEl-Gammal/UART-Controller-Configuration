#######################################################################
########  Variables  
#######################################################################
# --- Define Module name 
set design uart_regfile
# --- Simualtion Waveform stop on time 
set run_length 1us
# --- Check test_name  
if {![info exists testname]} {
	set testname "reset_default_test_w"
}
# --- debug waveform 
set debug 0
#######################################################################
########  Log file   
#######################################################################

set logfile "./results/${testname}.log"
transcript file $logfile
#######################################################################
########  Create Work and Resource Libraries  
#######################################################################
vlib work
vmap work ./work
#######################################################################
######## Compilation  
#######################################################################
# mfcu : MultiFileCompilationUnit
vlog -work work ./rtl/${design}.sv
vlog -work work ./testbench/tb_tasks_pkg.sv 
vlog -work work ./testbench/assertions.sv 
vlog -work work ./testbench/${design}_tb.sv 



#######################################################################
######## Simualtion  
#######################################################################
# --- All signals preserved  & Full hierarchy visibility
vsim -voptargs=+acc work.${design}_tb +TEST=$testname 

#######################################################################
######## waveform script 
#######################################################################
if {$debug == 1} { 
    view wave
    source ./scripts/waveform.do

} 
#######################################################################
######## Run Simulation   
#######################################################################
run $run_length
#######################################################################
######## Run Simulation   
#######################################################################

if {$debug == 0} { 
    quit -sim 
} else {
    wave zoom full
}
