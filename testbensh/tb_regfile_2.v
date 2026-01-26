module tb_regfile_2;
// =========================================================================
// Parameter 
// =========================================================================
parameter DATA_WIDTH = 16 ;
parameter N_Reg = 4 ;

// =========================================================================
//  Design Inputs and Outputs
// =========================================================================

logic clk;
logic rst_n;
logic wr_en;
logic [$clog2(N_Reg):0] wr_addr;
logic [DATA_WIDTH-1:0] wr_data;
logic [$clog2(N_Reg):0] rd_addr_a;
logic [$clog2(N_Reg):0] rd_addr_b;
logic uart_busy;
logic uart_error;
logic update_ok;
logic rd_valid_a;
logic rd_valid_b;
logic uart_enable;
logic [2:0] uart_mode;
logic [15:0] uart_rate;


logic [DATA_WIDTH-1:0] rd_data_a;
logic [DATA_WIDTH-1:0] rd_data_b;
logic [DATA_WIDTH-1:0] rd_data_a_0;
logic [DATA_WIDTH-1:0] rd_data_b_0;
logic rd_valid_a_0;
logic rd_valid_b_0;


// =========================================================================
//  DUT Instantiation
// =========================================================================
// ----- dut (Latency=1)
regfile #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(2), .READ_LATENCY(1), .N_Reg(N_Reg)) dut ( 
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
	.uart_rate (uart_rate));

// ----- dut_0 (Latency=0)
regfile #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(2), .READ_LATENCY(0), .N_Reg(N_Reg)) dut_0 ( 
	.clk (clk),
	.rst_n (rst_n),
	// Input software interface 
	.wr_en (wr_en),
	.wr_addr (wr_addr),
	.wr_data (wr_data),
	.rd_addr_a (rd_addr_a),
	.rd_addr_b (rd_addr_b),
	// Input Hardware interface 
	.uart_busy (uart_busy),
	.uart_error (uart_error),
	.update_ok (update_ok),
	// Outputs effected by latency  
	.rd_data_a (rd_data_a_0),
	.rd_data_b (rd_data_b_0),
	.rd_valid_a (rd_valid_a_0),
	.rd_valid_b (rd_valid_b_0),
	
	.uart_enable (),
	.uart_mode (),
	.uart_rate ());

// =========================================================================
// Tasks
// =========================================================================
// --- Task: Reset System
task automatic tb_reset();
	begin
		@(negedge clk);
		rst_n <= 0;
		repeat(5) @(negedge clk);
		rst_n <= 1;
		@(posedge clk);
		$display("[Time %0t] System Reset Released", $time);
	end
endtask

// --- Task: Write Task
task automatic write_reg;
    // --- Inputs ---
	input logic enable ; 
    input logic [$clog2(N_Reg):0] addr;
    input logic [DATA_WIDTH-1:0] data;
    
    begin
        @(negedge clk);        // Wait for negive edge
		wr_en 	 <= enable; 	
		wr_addr  <= addr;      // Set Address
        wr_data  <= data;      // Set Data        
        $display("[Task] Wrote %0d to Addr %0d at time %0t", data, addr, $time);
        
		@(negedge clk);        // Deassert Enable 
		wr_en 	 <= 'b0; 	
    end
endtask

// --- Task: Read Task
//--- Port A ( Latecny =1 )
task automatic read_reg_port_a;
    // --- Inputs ---
    input logic [$clog2(N_Reg):0] addr_a;
    input logic [DATA_WIDTH-1:0] expected_data_a;
    
    // --- Internal Variables ---
    logic [DATA_WIDTH-1:0] actual_data_a;
    
    begin
        // Drive the address
        @(negedge clk);
        rd_addr_a <= addr_a;
        // Capture the data
        @(negedge clk);
		actual_data_a = rd_data_a;        
        // Print
        if (actual_data_a == expected_data_a) begin
            $display("[%0t] PASS: Addr %0d - Expected %0d, Got %0d", 
                     $time, addr_a, expected_data_a, actual_data_a);
			$display("[%0t] PASS: Addr %0d - Expected %0b, Got %0b", 
                     $time, addr_a, expected_data_a, actual_data_a);		 
        end else begin
            $display("[%0t] FAIL: Addr %0d - Expected %0d, Got %0d", 
                     $time, addr_a, expected_data_a, actual_data_a);
            $display("[%0t] FAIL: Addr %0d - Expected %0b, Got %0b", 
                     $time, addr_a, expected_data_a, actual_data_a);
        end
    end
endtask

// --- Task: UART Peripheral Status 
task automatic set_uart_status(
	input logic busy ,
	input logic error, 
	input logic ok 
); 
	begin 
		@(negedge clk)
		uart_busy  <= busy;
		uart_error <= error;
		update_ok  <= ok;
	end 
endtask


/*
// ===============================
// Software inputs
// ===============================
// -- Read process
rd_addr_a = 0;	rd_addr_b=0;	
// -- Write process
wr_en = 0; wr_data = 0; 	wr_addr = 0 ;
// ===============================
// Hardware inputs
// ===============================
uart_busy=0; uart_error=0;	update_ok=0;
*/

// =========================================================================
// Main Test Process
// =========================================================================

initial begin	

	// ===============================
	// First Case (reset design)
	// ===============================
	$display(" ================================================ ");
	$display(" ================== First Case ================== ");
	tb_reset();
	set_uart_status(.ok(0),.error(0),.busy(0));	
	wr_en = 0;
	#20;
	// ===============================
	// Second Case (read all registers after reset )
	// ===============================
    $display(" ================================================ ");
	$display(" ================== Second Case ================== ");
	read_reg_port_a(.addr_a(0), .expected_data_a(16'b0));
	read_reg_port_a(.addr_a(1), .expected_data_a(16'd9600));
	read_reg_port_a(.addr_a(2), .expected_data_a(16'b0));
	read_reg_port_a(.addr_a(3), .expected_data_a(16'd0));
	// ===============================
	// Third Case (Write in CTRL Reg and check Register )   
	// ===============================
	$display(" ================================================ ");
	$display(" ================== Third Case ================== ");
	write_reg(.enable(1),.addr(0),.data('b1011));
	read_reg_port_a(.addr_a(0), .expected_data_a('b1011));
	

	// ===============================
	// Fourth Case (Write in BAUD to check Shadow state validate )   
	// ===============================
	$display(" ================================================ ");
	$display(" ================== Fourth Case ==================");
	set_uart_status(.ok(0),.error(0),.busy(0));
	write_reg(.enable(1),.addr('d1),.data('d4800));
	read_reg_port_a(.addr_a(1), .expected_data_a('d9600));
	set_uart_status(.ok(1),.error(0),.busy(0));
	read_reg_port_a(.addr_a(1), .expected_data_a('d4800));
	
	// ===============================
	// Fifth Case (Check controllability about Error and Busy bit )
	// ===============================
	$display(" ================================================ ");
	$display(" ================== Fifth Case ================== ");
	write_reg(.enable(1),.addr('d2),.data('b011));
	read_reg_port_a(.addr_a('d2), .expected_data_a('b0));
	

	// ===============================
	// Sixth Case (Check Sticky-bit )   
	// ===============================
	$display(" ================================================ ");
	$display(" ================== Sixth Case ================== ");
	
	set_uart_status(.ok(0),.error(1),.busy(1));
	read_reg_port_a(.addr_a('d2), .expected_data_a('b11));
	
	set_uart_status(.ok(0),.error(0),.busy(1));
	write_reg(.enable(1),.addr('d2),.data('b000));
	read_reg_port_a(.addr_a('d2), .expected_data_a('b11));
	
	write_reg(.enable(1),.addr('d2),.data('b11));
	read_reg_port_a(.addr_a('d2), .expected_data_a('b01));
	// ===============================
	// Seventh Case (Check OOB Read )    
	// ===============================
	$display(" ================================================== ");
	$display(" ================== Seventh Case ================== ");
	read_reg_port_a(.addr_a('d5), .expected_data_a('b0));
	# 10;  //Wait Time

	// ===============================
	// Eight Case (Check OOB Write )   
	// ===============================
	$display(" ================================================ ");
	$display(" ================== Eight Case ================== ");
	write_reg(.enable(1),.addr('d6),.data('b1));
	read_reg_port_a(.addr_a('d6), .expected_data_a('b0));
	

	// ===============================
	// Nine Case (RAW Hazard with Latency =0 )   >> manual test 
	// ===============================
	
	$display(" ================================================ ");
	$display(" ================== Nine Case ================== ");
	wr_en = 1'b1; wr_addr= 16'b0; wr_data=16'b111; rd_addr_b =16'b0;
	#1;
	if (rd_data_b_0 == wr_data) begin 
            $display("[%0t] PASS: Addr %0d - Expected %0b, Got_0 %0b ,Got_1 %0b", 
                     $time, rd_addr_b, wr_data, rd_data_b_0 ,rd_data_b);
        end else begin
            $display("[%0t] FAIL: Addr %0d - Expected %0b, Got_0 %0b ,Got_1 %0b", 
                     $time, rd_addr_b, wr_data,  rd_data_b_0 ,rd_data_b);
			end 
			
		#500 ;
	$stop;
	end

// =========================================================================
// Clock Generation
// =========================================================================
initial begin
	clk = 1'b0;
	forever #5 clk = ~clk;
end

endmodule$display(" ================== Nine Case ================== ");
