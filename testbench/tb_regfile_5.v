module tb_regfile_5;
// =========================================================================
// Parameter 
// =========================================================================
parameter  DATA_WIDTH = 16;
parameter  N_Reg = 4;
parameter  ADDR_WIDTH = 2;
parameter READ_LATENCY = 0;
// =========================================================================
//  Design Inputs and Outputs
// =========================================================================
logic clk;
logic rst_n;
logic wr_en;
logic [$clog2(N_Reg):0] wr_addr, rd_addr_a, rd_addr_b;
logic [DATA_WIDTH-1:0] wr_data;
logic uart_busy, uart_error, update_ok;
logic uart_enable;
logic [2:0]  uart_mode;
logic [15:0] uart_rate;
logic [DATA_WIDTH-1:0] rd_data_a, rd_data_b;
logic rd_valid_a, rd_valid_b;

// =========================================================================
//  DUT Instantiation
// =========================================================================
// ----- dut 
regfile #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .READ_LATENCY(READ_LATENCY), .N_Reg(N_Reg)) dut ( 
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
 bind regfile assertions #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .READ_LATENCY(READ_LATENCY), .N_Reg(N_Reg)) u_sva (
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




// =========================================================================
// Function Coverage 
// =========================================================================
covergroup rst_fcvg @(posedge clk);
cp_rst_n: coverpoint rst_n {
	bins active_rst 	= {0} ;  
	bins de_active_rst 	= {1} ; 
}
endgroup 

covergroup regfile_fcvg @(posedge clk) iff(rst_n);


cp_wr_en: coverpoint wr_en {
	bins wr_active 	= {1} ;  
	bins wr_stop	= {0} ; 
}

// ---- Write addresses Points
cp_wr_addr: coverpoint wr_addr {

 bins w_ctrl   = {0};
 bins w_baud   = {1};
 bins w_status = {2};
 bins w_oob    = default;
 
}

// ---- Read addresses Points om Port-a
cp_rd_addr_a: coverpoint rd_addr_a {
 bins r_ctrl_a   = {0};
 bins r_baud_a   = {1};
 bins r_status_a = {2};
 bins r_oob_a    = default;
 }
// ---- Read addresses Points om Port-b
cp_rd_addr_b: coverpoint rd_addr_b {
 bins r_ctrl_b   = {0};
 bins r_baud_b   = {1};
 bins r_status_b = {2};
 bins r_oob_b    = default;
 
}

// ---- update_ok 
cp_update_ok: coverpoint update_ok {
	bins stall_shadow 	= {0} ;  
	bins update_baud 	= {1} ; 

}

cp_uart_error: coverpoint uart_error {
	bins de_active_error	= {0} ;  
	bins active_error 		= {1} ; 

}

// Check combinations of Read/Write vs Address
cr_wr_en_addr	: cross cp_wr_en,wr_addr;
cr_update_rd_a	: cross cp_update_ok,rd_addr_a;
cr_update_rd_b	: cross cp_update_ok,rd_addr_b;
cr_error_wr		: cross cp_uart_error,wr_addr;
cr_error_rd_a	: cross cp_uart_error,rd_addr_a;
cr_error_rd_b	: cross cp_uart_error,rd_addr_b;

endgroup 

// =========================================================================
// Clock Generator
// =========================================================================
initial begin
	clk = 0;
	forever #5 clk = ~clk;
end
// =========================================================================
// Tasks
// =========================================================================
// ---- Reset System
task automatic tb_reset();
	begin
		rst_n		<= 0;
		wr_en		<= 0;
		wr_addr		<= 'b0;
		wr_data		<= 'b0;
		uart_busy 	<= 'b0;
		uart_error	<= 'b0;
		update_ok	<= 'b0;
		rd_addr_a 	<= 'b0;
		rd_addr_b 	<= 'b0;
		repeat(5) @(negedge clk);
		rst_n <= 1;
	end
endtask


// ---- Write Task
task automatic write_reg;
    // --- Inputs ---
	input logic enable ; 
    input logic [$clog2(N_Reg):0] addr;
    input logic [DATA_WIDTH-1:0] data;
    begin
        @(negedge clk);      
		wr_en 	 <= enable; 	
		wr_addr  <= addr;     
        wr_data  <= data;                 
		@(negedge clk);      
		wr_en 	 <= 'b0; 	
    end
endtask


//--- Read Task Port_a 
task automatic read_port_a;
input logic [$clog2(N_Reg):0] addr_a;
logic [DATA_WIDTH-1:0] actual_data_a;
    begin
	    @(negedge clk);
		rd_addr_a = addr_a;

        if (READ_LATENCY == 1 ) begin 
			@(negedge clk);
			actual_data_a = rd_data_a;
			end 
		else begin
			#1;		
			actual_data_a = rd_data_a;
			end 
		$display("[%0t]  Addr_a %0d - data_a %0d", 
				$time, addr_a, actual_data_a);

	end
endtask

//--- Read Task Port_b
task automatic read_port_b;
input logic [$clog2(N_Reg):0] addr_b;
logic [DATA_WIDTH-1:0] actual_data_b;
    begin
	    @(negedge clk);
		rd_addr_b = addr_b;
		
        if (READ_LATENCY == 1 ) begin 
			@(negedge clk);
			actual_data_b = rd_data_b;
			end 
		else begin 	
			#1;
			actual_data_b = rd_data_b;
			end 
		$display("[%0t]  Addr_b %0d - data_b %0d", 
				$time, addr_b, actual_data_b);

	end
endtask

// --- Task: UART Peripheral Status 
task automatic set_uart_status;
input logic busy, error,ok ;
	@(negedge clk)
	uart_busy  <= busy;
	uart_error <= error;
	update_ok  <= ok;	 
endtask

// --- Task: Wait 
task automatic Wait;
	input int number_cycles;
	#(10 * number_cycles);
endtask
int i;
// =========================================================================
// Main Test Process
// =========================================================================
// Instantiate the coverage group
initial begin
 rst_fcvg 	cg_inst_rst =new();	
 regfile_fcvg cg_inst = new();
end
initial begin
	$dumpfile("waveform.vcd");
	$dumpvars(0, tb_regfile_5);
	// ===============================
	// (Reset behavior) <Smoke-Test>
	// ===============================
	$display(" ================== TC_01 ================== ");
	$display(" ========== reset_default_test_w ========= ");
	tb_reset();
	set_uart_status(.ok(0),.error(0),.busy(0));	
	Wait(2.5);
	$display(" ================== TC_02 ================== ");
	$display(" ========== reset_default_test_r ========= ");
	for(i=0; i< N_Reg ;i=i+1)	 begin 
		read_port_a(.addr_a(i));
		Wait(1);
		end 
	// ====================================
	// (Register map Read/Write operations) 
	// =====================================
	$display(" ================== TC_03 ================== ");
	$display(" ======== write_read_operation_test ======== ");
	write_reg(.enable(1),.addr(0),.data('b1011));
	read_port_b(.addr_b(0));
	$display(" Check Memory on simulation Waveform ");
	// ===================================================
	// (Out of Range Read/Write operations) <Negtive-Test>
	// ===================================================
	$display(" ================== TC_04 ================== ");
	$display(" ========== write_read_oob_test ============ ");
	write_reg(.enable(1),.addr(6),.data('b1111));
	read_port_a(.addr_a(6));
	read_port_b(.addr_b(7));
	$display(" OOB Checker %0t ",$time);
	// ===================================
	// (Hazard Read/Write operations) <Self-Checking>
	// ====================================
	$display(" ================== TC_05 ================== ");
	$display(" ========== write_read_hazard_test ========= ");
	@(negedge clk);
	wr_en = 'b1; wr_addr= 16'b0; wr_data=16'b111; rd_addr_a =16'b0;
	Wait(0.1);
	if (READ_LATENCY == 0) begin 
		if (rd_data_a == wr_data)
			$display("%0t PASS RAW Hazard Check at address %0d",$time ,rd_addr_a);
		else 	
			$display("%0t FAIL RAW Hazard Check at address %0d and rd_data_a %0b",$time ,rd_addr_a,rd_data_a);
		end 
	else 	
		$display("%0t READ_LATENCY = 1 ,SO ignore RAW Self-Checkc rd_add_a %0b rd_data_a %0b",$time ,rd_addr_a,rd_data_a);
	
	Wait(1);
	@(negedge clk);
	wr_en = 1'b1; wr_addr= 16'b10; wr_data=16'b111; rd_addr_b =16'b10;
	Wait(0.1);
	if (READ_LATENCY == 0) begin 
		if (rd_data_b == wr_data)
			$display("%0t PASS RAW Hazard Check at address %0d",$time ,rd_addr_b);
		else 	
			$display("%0t FAIL RAW Hazard Check at address %0d and rd_data_b %0b",$time ,rd_addr_b,rd_data_b);
	end 
	Wait(1);
	wr_en = 1'b0;
	Wait(1);
	
	// ===============================
	// STICKY Bit Error <Self-Checking>
	// ===============================
	$display(" ================== TC_06 ================== ");
	$display(" ============= sticky_bit_test ============= ");
	write_reg(.enable(1),.addr(2),.data('b10));
	read_port_b(.addr_b(2));
	Wait(1);
	set_uart_status(.ok(0),.error(1),.busy(0));	
	Wait(1);
	set_uart_status(.ok(0),.error(0),.busy(0));	
	Wait(1);
	write_reg(.enable(1),.addr(2),.data('b10));
	read_port_b(.addr_b(2));
	if (READ_LATENCY == 1) begin  
		if (rd_data_b == 'b00)
			$display("%0t PASS STICKY Bit Error Check ",$time );
		else 	
			$display("%0t FAIL STICKY Bit Error Check rd_data_b %0b",$time ,rd_data_b);
		end 
	else  
		$display("%0t Ignore STICKY Bit Error Check READ_LATENCY = 0 ",$time );
	Wait(3);
	// ===============================
	// Shadow State <Self-Checking>
	// ===============================
	$display(" ================== TC_07 ================== ");
	$display(" ============ shadow_state_test ============ ");
	write_reg(.enable(1),.addr(1),.data('d4800));
	read_port_a(.addr_a(1));
	Wait(1);
	$display(" ================== TC_08 ================== ");
	set_uart_status(.ok(1),.error(1),.busy(0));
	Wait(1);
	read_port_a(.addr_a(1));
	if (rd_data_a == 'd4800)
		$display("%0t PASS Shadow State Check ",$time );
	else 	
		$display("%0t FAIL Shadow State Check rd_data_a %0d",$time ,rd_data_a);
	// ===============================
	// Reserved Register <Self-Checking>/<Negtive-Test>
	// ===============================
	$display(" ================== TC_09 ================== ");
	$display(" ============ write_reserved_register ============ ");
	write_reg(.enable(1),.addr(2),.data('d01));
	read_port_b(.addr_b(1));
	if (rd_data_b != 'd01)
		$display("%0t PASS Reserved Register Check ",$time );
	else 	
		$display("%0t FAIL hadow Reserved Register rd_data_b %0d",$time ,rd_data_b);
	Wait(5);

	// ===============================================
	// (Register map Read/Write operations) <Negtive-Test>
	// ===============================================
	$display(" ================== TC_10 ================== ");
	$display(" ============ write_negtive_test =========== ");
	write_reg(.enable(0),.addr(0),.data('hABC));
	read_port_b(.addr_b(0));
	Wait(10);
	$stop;
	end 
endmodule 
	
