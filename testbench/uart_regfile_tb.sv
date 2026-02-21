module uart_regfile_tb;
// =========================================================================
// Parameter 
// =========================================================================
parameter DATA_WIDTH = 16;
parameter READ_LATENCY =0;
parameter N_Reg = 4;
parameter Fun_Cov = 0;
parameter Assertion = 0;

// =========================================================================
//  Design Inputs and Outputs
// =========================================================================
logic clk;
logic rst_n;
logic wr_en;
logic [$clog2(N_Reg):0] wr_addr, rd_addr_a, rd_addr_b;
logic [DATA_WIDTH-1:0] wr_data;
logic [1:0] uart_error;
logic uart_busy, update_ok;
logic uart_enable;
logic [2:0]  uart_mode;
logic [15:0] uart_rate;
logic [DATA_WIDTH-1:0] rd_data_a, rd_data_b;
logic rd_valid_a, rd_valid_b;

// =========================================================================
//  DUT Instantiation
// =========================================================================
// ----- dut 
uart_regfile #(.DATA_WIDTH(DATA_WIDTH), .READ_LATENCY(READ_LATENCY), .N_Reg(N_Reg)) dut ( 
	.clk (clk),
	.rst_n (rst_n),
	.wr_en (wr_en),
	.wr_addr (wr_addr),
	.wr_data (wr_data),
	.rd_addr_a (rd_addr_a),
	.rd_addr_b (rd_addr_b),
	.rd_data_a (rd_data_a),
	.rd_data_b (rd_data_b),
	.uart_busy (uart_busy),
	.uart_error (uart_error),
	.update_ok (update_ok),
	.rd_valid_a (rd_valid_a),
	.rd_valid_b (rd_valid_b),
	.uart_enable (uart_enable),
	.uart_mode (uart_mode),
	.uart_rate (uart_rate)
	);

// =========================================================================
//  Bind Instantiation
// =========================================================================
`ifdef Assertion 
 bind uart_regfile assertions #(.DATA_WIDTH(DATA_WIDTH), .READ_LATENCY(READ_LATENCY), .N_Reg(N_Reg)) u_sva (
	.clk (clk),
	.rst_n (rst_n),
	.wr_en (wr_en),
	.wr_addr (wr_addr),
	.wr_data (wr_data),
	.rd_addr_a (rd_addr_a),
	.rd_addr_b (rd_addr_b),
	.rd_data_a (rd_data_a),
	.rd_data_b (rd_data_b),
	.uart_busy (uart_busy),
	.uart_error (uart_error),
	.update_ok (update_ok),
	.rd_valid_a (rd_valid_a),
	.rd_valid_b (rd_valid_b),
	.uart_enable (uart_enable),
	.uart_mode (uart_mode),
	.uart_rate (uart_rate),       
	.mem(dut.mem)  // Internal Register 
    );


`endif

// =========================================================================
// Function Coverage 
// =========================================================================
`ifdef Fun_Cov
	covergroup rst_fcvg @(posedge clk) ;
	cp_rst_n: coverpoint rst_n {
		bins active_rst 	= {0} ;  
		bins de_active_rst 	= {1} ; 
	}
	endgroup 

	covergroup regfile_fcvg @(posedge clk) ;


	cp_wr_en: coverpoint wr_en  iff(rst_n) {
		bins wr_active 	= {1} ;  
		bins wr_stop	= {0} ; 
	}

	// ---- Write addresses Points
	cp_wr_addr: coverpoint wr_addr iff(rst_n) {

	 bins w_ctrl   = {0};
	 bins w_baud   = {1};
	 bins w_status = {2};
	 bins w_oob    = default;
	 
	}

	// ---- Read addresses Points om Port-a
	cp_rd_addr_a: coverpoint rd_addr_a iff(rst_n) {
	 bins r_ctrl_a   = {0};
	 bins r_baud_a   = {1};
	 bins r_status_a = {2};
	 bins r_oob_a    = default;
	 }
	// ---- Read addresses Points om Port-b
	cp_rd_addr_b: coverpoint rd_addr_b iff(rst_n) {
	 bins r_ctrl_b   = {0};
	 bins r_baud_b   = {1};
	 bins r_status_b = {2};
	 bins r_oob_b    = default;
	 
	}

	// ---- update_ok 
	cp_update_ok: coverpoint update_ok iff(rst_n) {
		bins stall_shadow 	= {0} ;  
		bins update_baud 	= {1} ; 

	}

	cp_uart_error: coverpoint uart_error iff(rst_n) {
		bins de_active_error	= {0} ;  
		bins active_error 		= {1} ; 

	}

	// Check combinations of Read/Write vs Address
	cr_wr_en_addr	: cross cp_wr_en,cp_wr_addr;
	cr_update_rd_a	: cross cp_update_ok,cp_rd_addr_a;
	cr_update_rd_b	: cross cp_update_ok,cp_rd_addr_b;
	cr_error_wr		: cross cp_uart_error,cp_wr_addr;
	cr_error_rd_a	: cross cp_uart_error,cp_rd_addr_a;
	cr_error_rd_b	: cross cp_uart_error,cp_rd_addr_b;

	endgroup 
rst_fcvg 	cg_inst_rst;
regfile_fcvg cg_inst;

initial begin
	cg_inst_rst =new();	
	cg_inst = new();
end
`endif


// =========================================================================
// Clock Generator
// =========================================================================
initial begin
	clk = 0;
	forever #5 clk = ~clk;
end

// =========================================================================
// Package Tasks
// =========================================================================
import tb_tasks_pkg::*;

// =========================================================================
// Waveform dumpfile
// =========================================================================

initial begin
	$dumpfile("waveform.vcd");
	$dumpvars(0, uart_regfile_tb);
end 

// =========================================================================
// Main Test Process
// =========================================================================
// Instantiate the coverage group
initial begin 
	
    string testname;
	//Read command-line arguments +TEST= 
	if (!$value$plusargs("TEST=%s", testname)) begin
       	testname = "reset_default_test_w"; // default
        $display(" Running TEST = default ");
	end
	$display("==================================================");
	$display(" Running TEST = %s", testname);
	$display("==================================================");
	
	// Stuck 
	tb_reset(clk,rst_n,wr_en,wr_addr,wr_data,rd_addr_a,rd_addr_b,uart_busy,uart_error,update_ok); 
	#10;
	$display(" READ_LATENCY = %d", READ_LATENCY);
	run_selected_test (.testname(testname),.clk(clk),.rd_data_a(rd_data_a),.rd_data_b(rd_data_b),.rst_n(rst_n),
	                   .wr_en(wr_en),.wr_addr(wr_addr),.wr_data(wr_data),.rd_addr_a(rd_addr_a),.rd_addr_b(rd_addr_b),
					   .uart_busy(uart_busy),.uart_error(uart_error),.update_ok(update_ok));
	
	$display("TEST %s DONE.", testname);
	Wait(3);
	$stop;
end
endmodule 
	


