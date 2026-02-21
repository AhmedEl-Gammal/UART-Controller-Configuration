# --- Clear existing waves
delete wave *
#######################################################################
######## Configuration 
#######################################################################
configure wave -namecolwidth 150;   # First Coulum width
configure wave -valuecolwidth 75;   # Second Coulum width
configure wave -justifyvalue left;  # Data Display on waveform from left   
configure wave -signalnamewidth 1;  # just name of signal   
configure wave -timeline 0;         # Start from 0 
#######################################################################
######## Parameters 
#######################################################################
add wave -divider "=== Parameters ===" 
add wave -group "Parameters" -position end  sim:/${design}_tb/READ_LATENCY
add wave -group "Parameters" -position end  sim:/${design}_tb/READ_LATENCY
add wave -group "Parameters" -position end  sim:/${design}_tb/DATA_WIDTH
add wave -group "Parameters" -position end  sim:/${design}_tb/N_Reg

#######################################################################
######## Clock & Reset 
#######################################################################
add wave -divider "=== clock & reset ===" 
add wave -group "clock&reset" -position end  sim:/${design}_tb/clk
add wave -group "clock&reset" -position end  sim:/${design}_tb/rst_n
#######################################################################
######## Write_Data_In 
#######################################################################
add wave -divider "=== w_data_in ===" 
add wave -group "w_data_in" -color Yellow                 -position end  sim:/${design}_tb/wr_en
add wave -group "w_data_in" -color Yellow -radix unsigned -position end  sim:/${design}_tb/wr_addr
add wave -group "w_data_in" -color Yellow -radix unsigned -position end  sim:/${design}_tb/wr_data
#######################################################################
######## PortA  
#######################################################################
add wave -divider "=== port_a ===" 
add wave -group "port_a" -color VioletRed -radix unsigned -position end  sim:/${design}_tb/rd_addr_a
add wave -group "port_a" -color VioletRed -radix unsigned -position end  sim:/${design}_tb/rd_data_a
add wave -group "port_a" -color VioletRed                 -position end  sim:/${design}_tb/rd_valid_a
#######################################################################
######## PortB 
#######################################################################
add wave -divider "=== port_b ===" 
add wave -group "port_b" -color Blue -radix unsigned -position end  sim:/${design}_tb/rd_addr_b
add wave -group "port_b" -color Blue -radix unsigned -position end  sim:/${design}_tb/rd_data_b
add wave -group "port_b" -color Blue                 -position end  sim:/${design}_tb/rd_valid_b
#######################################################################
######## Memory & ShadowState  
#######################################################################
add wave -divider "=== Internal ===" 
add wave -group "Internal" -color Firebrick -radix unsigned -position end  sim:/${design}_tb/dut/mem
add wave -group "Internal" -color Orchid    -radix unsigned -position end  sim:/${design}_tb/dut/shadow_reg
#######################################################################
######## Inputs_Hardware  
#######################################################################
add wave -divider "=== hard_input ===" 
add wave -group "hard_input" -color SkyBlue -position end  sim:/${design}_tb/uart_busy
add wave -group "hard_input" -color SkyBlue -position end  sim:/${design}_tb/uart_error
add wave -group "hard_input" -color SkyBlue -position end  sim:/${design}_tb/update_ok
#######################################################################
######## Outputs_Software  
#######################################################################
add wave -divider "=== soft_output ===" 
add wave -group "soft_output" -color YellowGreen -position end  sim:/${design}_tb/uart_enable
add wave -group "soft_output" -color YellowGreen -position end  sim:/${design}_tb/uart_mode
add wave -group "soft_output" -color YellowGreen -position end  sim:/${design}_tb/uart_rate