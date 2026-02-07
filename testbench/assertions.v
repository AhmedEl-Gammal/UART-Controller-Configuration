module assertions #(
parameter  DATA_WIDTH = 16 ,
parameter  N_Reg = 4 ,
parameter  ADDR_WIDTH = 2,
parameter READ_LATENCY = 0) (
input logic clk,
input logic rst_n,
input logic wr_en,
input logic [$clog2(N_Reg):0] wr_addr, rd_addr_a, rd_addr_b,
input logic [DATA_WIDTH-1:0] wr_data ,
input logic uart_busy, uart_error, update_ok ,
input logic uart_enable, 
input logic [2:0]  uart_mode,
input logic [15:0] uart_rate,
input logic [DATA_WIDTH-1:0] rd_data_a, rd_data_b,
input logic rd_valid_a, rd_valid_b,
input logic [DATA_WIDTH-1:0] mem [N_Reg-1:0]
);


// -------------------------------------------------
// ---- checking that reset Initalize the registers
// -------------------------------------------------
property p_rst_reg ;
	@(posedge clk) 
		// rose(condition) triggers once when the condition transitions from low to high
		$rose(rst_n)|-> (mem[0] == 'b0 &&  mem[1] == 'd9600 &&  mem[2] == 'b0&& mem[3] == 'b0);  
endproperty 

a_mem_checker: assert property(p_rst_reg)
	else $error(" Time %0t, There are other memory values(Unknown) initialized during the reset process.",$time);




// -------------------------------------------------
// ---- check if X propagate
// -------------------------------------------------
property p_no_x_read ;
	@(posedge clk)
	// Ignore checks while reset is active 
	disable iff (!rst_n) 
	(!$isunknown(rd_data_a) && !$isunknown(rd_data_b));
endproperty 
a_outputs_checker: assert property(p_no_x_read	)
	else $error("There are unknown data on outptus ports %0t through reset process",$time);

// -------------------------------------------------
// ---- RAW policy (READ_LATENCY==0)
// -------------------------------------------------
generate if (READ_LATENCY == 0) begin 
	property p_raw_bypass_a;
		@(posedge clk ) wr_en && (rd_addr_a == wr_addr) |-> (wr_data == rd_data_a) ; 
	endproperty
	
	a_raw_hazard_checker_a: assert property(p_raw_bypass_a)
		else $error("Port A,RAW failed  %0t",$time);
	
	property p_raw_bypass_b;
		@(posedge clk ) wr_en && (rd_addr_b == wr_addr) |-> (wr_data == rd_data_b) ; 
	endproperty
	
	a_raw_hazard_checker_b: assert property(p_raw_bypass_b)
		else $error("Port B,RAW failed %0t",$time);	
	end
endgenerate 

// -------------------------------------------------
// ---- OOB 
// -------------------------------------------------	
// --- ##[0:1] Check across different cycles due to latency variation 
property p_oob_safe_read_a;
	@(posedge clk )
	(rd_addr_a >= N_Reg) |-> ##[0:1](rd_data_a == 'b0) ;
	endproperty
	
a_oob_a:assert property (p_oob_safe_read_a)
	else $error("Port A,OOB Condition is Failed %0t ",$time);

property p_oob_safe_read_b;
	@(posedge clk )
	(rd_addr_b >= N_Reg) |-> ##[0:1] (rd_data_b == 'b0) ;
	endproperty
	
a_oob_b:assert property (p_oob_safe_read_b)
	else $error("Port B, OOB Condition is Failed %0t",$time);
		

// -------------------------------------------------
// ---- Shadow State  
// -------------------------------------------------	
property p_shadow_state;
	@(posedge clk ) (mem[1] != $past(mem[1])) |-> update_ok;
	endproperty
a_shadow_state:assert property (p_shadow_state);

endmodule 
