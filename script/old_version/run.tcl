vsim -voptargs=+acc work.tb_regfile
add wave -position end  sim:/tb_regfile/clk
add wave -position end  sim:/tb_regfile/rst_n
add wave -position end  sim:/tb_regfile/wr_en
add wave -position end  sim:/tb_regfile/wr_addr
add wave -position end  sim:/tb_regfile/wr_data
add wave -position end  sim:/tb_regfile/rd_addr_a
add wave -position end  sim:/tb_regfile/rd_addr_b
add wave -position end  sim:/tb_regfile/rd_data_a
add wave -position end  sim:/tb_regfile/rd_data_b
add wave -position end  sim:/tb_regfile/uart_busy
add wave -position end  sim:/tb_regfile/uart_error
add wave -position end  sim:/tb_regfile/update_ok
add wave -position end  sim:/tb_regfile/rd_valid_a
add wave -position end  sim:/tb_regfile/rd_valid_b
add wave -position end  sim:/tb_regfile/uart_enable
add wave -position end  sim:/tb_regfile/uart_mode
add wave -position end  sim:/tb_regfile/uart_rate
add wave -position end  sim:/tb_regfile/dut/mem
add wave -position end  sim:/tb_regfile/dut/shadow_reg
run
#quit -sim



vsim -voptargs=+acc work.tb_regfile_2
add wave -position end  sim:/tb_regfile_2/DATA_WIDTH
add wave -position end  sim:/tb_regfile_2/N_Reg
add wave -position end  sim:/tb_regfile_2/clk
add wave -position end  sim:/tb_regfile_2/rst_n
add wave -position end  sim:/tb_regfile_2/wr_en
add wave -position end  sim:/tb_regfile_2/wr_addr
add wave -position end  sim:/tb_regfile_2/wr_data
add wave -position end  sim:/tb_regfile_2/rd_addr_a
add wave -position end  sim:/tb_regfile_2/rd_addr_b
add wave -position end  sim:/tb_regfile_2/uart_busy
add wave -position end  sim:/tb_regfile_2/uart_error
add wave -position end  sim:/tb_regfile_2/update_ok
add wave -position end  sim:/tb_regfile_2/rd_valid_a
add wave -position end  sim:/tb_regfile_2/rd_valid_b
add wave -position end  sim:/tb_regfile_2/uart_enable
add wave -position end  sim:/tb_regfile_2/uart_mode
add wave -position end  sim:/tb_regfile_2/uart_rate
add wave -position end  sim:/tb_regfile_2/rd_data_a
add wave -position end  sim:/tb_regfile_2/rd_data_b
add wave -position end  sim:/tb_regfile_2/rd_data_a_0
add wave -position end  sim:/tb_regfile_2/rd_data_b_0
add wave -position end  sim:/tb_regfile_2/rd_valid_a_0
add wave -position end  sim:/tb_regfile_2/rd_valid_b_0
add wave -position end  sim:/tb_regfile_2/dut/mem
add wave -position end  sim:/tb_regfile_2/dut/shadow_reg
run
quit -sim
