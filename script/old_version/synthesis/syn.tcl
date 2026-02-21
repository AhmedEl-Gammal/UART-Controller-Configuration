# ----- Setup_file ----- # 

# --- Define Search path & Libraries ---- # 
set_app_var search_path "/home/ICer/Downloads/Lib/synopsys/models"


#set_app_var target_library "saed90nm_max_hth_lvt.db"

set_app_var target_library "saed90nm_max.db" ; # Good PNR Flow 
set_app_var link_library "* $target_library"

# --- Remove any work --- #
# Repitive operations 
sh rm -rf work
sh mkdir -p work


# For define enviroment files for reduced run time of tools to store intermideate files 
define_design_lib work -path ./work ; 


# --- Synthesis Commands ---- #
# --- Define Top Module --- # 
set design uart_regfile
# - Check Syntax Errors 
analyze -lib work -format sverilog ../rtl/${design}.sv

# - Translate to getech netlist and check linting design issues multi-driven nets, width mismatch  
elaborate $design -lib work

# - Return name of current design  
current_design 

# - Checks for detects any errors in design 
check_design

# -- Apply Constraints on Design 
source ../cons/cons.tcl
# ---- Budget Clock --- # 
create_clock -name clk -period 10 -waveform {0 5} [get_ports clk]
set_clock_uncertainty 0.60 [get_clocks]


# ---- Model external ---- #
set_output_delay -max 0.50 -clock [get_clocks clk] [all_outputs]



# - locate all of the designs and library components referenced in the current design and connect them to the current design.
link

# -- Optimize and mapping 
compile -map_effort high
#compile_ultra


# --Reports 
report_area > ../report_syn/synth_area.rpt
report_timing > ../report_syn/critical_Path_timing.rpt
report_power > ../report_syn/synth_power.rpt
report_cell > ../report_syn/synth_cells.rpt
report_qor  > ../report_syn/synth_qor.rpt
report_resources > ../report_syn/synth_resources.rpt
report_timing > ../report_syn/synth_resources.rpt
report_constraints -all_violators > ../report_syn/syn_violations.rpt
 
#Save For Synopsys Design Constrains
write_sdc ../output/${design}.sdc 

# Some Rules of names For Enhanced work tools through process 
define_name_rules  no_case -case_insensitive
change_names -rule no_case -hierarchy
change_names -rule verilog -hierarchy
report_names -rules verilog

set verilogout_no_tri	 true
set verilogout_equation  false

# Save Results output 
write -hierarchy -format verilog -output ../output/${design}.v 

# Design Compiler Binary Format  binary file format used to store the synthesized design datacontains all the information about the synthesized design
write -f ddc -hierarchy -output ../output/${design}.ddc   

start_gui

