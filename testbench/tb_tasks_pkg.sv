package tb_tasks_pkg; 

// =========================================================================
// Parameter 
// =========================================================================
parameter DATA_WIDTH = 16;
parameter READ_LATENCY =0;
parameter N_Reg = 4;

	// =========================================================================
	// Tasks
	// =========================================================================
	// ---- Reset System
	task automatic tb_reset(
		ref  logic                     clk,
		ref  logic                     rst_n,
   	    ref  logic                     wr_en,
	    ref  logic [$clog2(N_Reg):0]   wr_addr,	
	    ref  logic [DATA_WIDTH-1 :0]   wr_data,    	
	    ref  logic [$clog2(N_Reg):0]   rd_addr_a,  	
	    ref  logic [$clog2(N_Reg):0]   rd_addr_b, 
	    ref  logic        uart_busy,
	    ref  logic [1:0]  uart_error,  
	    ref  logic        update_ok
		);
		begin
			rst_n		= 0;
			wr_en		= 0;
			wr_addr		= 'b0;
			wr_data		= 'b0;
			uart_busy 	= 'b0;
			uart_error	= 'b0;
			update_ok	= 'b0;
			rd_addr_a 	= 'b0;
			rd_addr_b 	= 'b0;
			repeat(5)@(negedge clk);
			rst_n = 'b1;
			
		end
	endtask

	// ---- Write Task
	task automatic write_reg(
		// --- ref --- 
		ref    logic clk,
   	    ref  logic          wr_en,
	    ref  logic [$clog2(N_Reg):0]   wr_addr,	
	    ref  logic [DATA_WIDTH-1 :0]   wr_data, 		
		// --- Inputs ---
		input logic enable , 
		input logic [$clog2(N_Reg):0] addr,
		input logic [DATA_WIDTH-1:0] data
		);
		begin
			@(negedge clk);      
			wr_en 	 = enable; 	
			wr_addr  = addr;     
			wr_data  = data;                 
			@(negedge clk);      
			wr_en 	 = 'b0; 	
		end
	endtask


	//--- Read Task Port_a 
	task automatic read_port_a(
		// --- ref --- 
	    ref    logic clk,
		ref    logic [$clog2(N_Reg):0]   rd_addr_a,
		ref  logic [DATA_WIDTH-1 :0]   rd_data_a,  
		// --- Inputs ---
		input  logic [$clog2(N_Reg):0]   addr_a

		);
		begin
			// internal 
	        logic [DATA_WIDTH-1:0]           actual_data_a;
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
	task automatic read_port_b (
		// --- ref --- 
		ref    logic clk,
		ref    logic [$clog2(N_Reg):0]   rd_addr_b,
		ref  logic [DATA_WIDTH-1 :0]   rd_data_b, 

		// --- Inputs ---
		input  logic [$clog2(N_Reg):0]   addr_b
			);
	    begin
	    // internal 
		logic [DATA_WIDTH-1:0]           actual_data_b;
		
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
	task automatic set_uart_status(
	   ref  logic       clk,
		// --- ref --- 
	   ref   logic       uart_busy, update_ok,
	   ref   logic [1:0] uart_error,   
		// --- Inputs ---
	   input logic       busy, ok,
	   input logic [1:0] error
		);
		@(negedge clk)
		uart_busy  = busy;
		uart_error = error;
		update_ok  = ok;	 
	endtask

	// --- Task: Wait 
	task automatic Wait(
		input int number_cycles
		);
		#(10 * number_cycles);
	endtask
	
    // =========================================================================
	// Dispatcher 
	// =========================================================================

    task automatic run_selected_test ( 
		// --- ref drive signals --- 
		ref  logic                     clk,
		ref  logic                     rst_n,
		ref logic  [DATA_WIDTH-1 :0]   rd_data_a,rd_data_b,
   	    ref  logic                     wr_en,
	    ref  logic [$clog2(N_Reg):0]   wr_addr,	
	    ref  logic [DATA_WIDTH-1 :0]   wr_data,    	
	    ref  logic [$clog2(N_Reg):0]   rd_addr_a,  	
	    ref  logic [$clog2(N_Reg):0]   rd_addr_b, 
	    ref  logic                     uart_busy,
	    ref  logic [1:0]               uart_error,  
	    ref  logic                     update_ok,
		// --- inputs only reads ---- 
		input  string                  testname
		);
    begin 
		case (testname) 			
		// ===============================
		// (Reset behavior) <Smoke-Test>
		// ===============================
			"reset_default_test_w": begin
				$display(" ========== reset_default_test_w ========= ");
				tb_reset(clk,rst_n,wr_en,wr_addr,wr_data,rd_addr_a,rd_addr_b,uart_busy,uart_error,update_ok);
				Wait(2.5);
			end 
			"reset_default_test_r": begin 
				//$display(" ========== reset_default_test_r ========= ");
				for(int i=0; i< N_Reg ;i=i+1)    begin 
					read_port_a(clk,rd_addr_a,rd_data_a,.addr_a(i));
					$display(" [%0t]Read reset Memory address [%0d] ",$time,i);
					Wait(1);
				end 
			end 
		// ====================================
		// (Register map Read/Write operations) 
		// =====================================
			"write_read_operation_test": begin 
				$display(" ======== write_read_operation_test ======== ");
				write_reg(.clk(clk),.wr_en(wr_en),.wr_addr(wr_addr),.wr_data(wr_data),.enable(1),.addr(6),.data('b1111));
				read_port_b(clk,rd_addr_b,rd_data_b,.addr_b(7));
			end 

		// ===================================================
		// (Out of Range Read/Write operations) <Negtive-Test>
		// ===================================================		
			"write_read_oob_test": begin 
				//$display(" ========== write_read_oob_test ============ ");
				write_reg(.clk(clk),.wr_en(wr_en),.wr_addr(wr_addr),.wr_data(wr_data),.enable(1),.addr(6),.data('b1111));
				read_port_a(clk,rd_addr_a,rd_data_a,.addr_a(6));
				read_port_b(clk,rd_addr_b,rd_data_b,.addr_b(7));
			end 
		// ===================================
		// (Hazard Read/Write operations) <Self-Checking>
		// ====================================
			"write_read_hazard_test":begin
				//$display(" ========== write_read_hazard_test ========= ");
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
			end 
		// ===============================
		// STICKY Bit Error <Self-Checking>
		// ===============================
			"sticky_bit_test": begin
				$display(" ============= sticky_bit_test ============= ");
				read_port_b(clk,rd_addr_b,rd_data_b,.addr_b(2));
				Wait(1);
				set_uart_status(clk,uart_busy,update_ok,uart_error,.busy(0),.ok(0),.error(2'b01));	
				Wait(1);
				set_uart_status(clk,uart_busy,update_ok,uart_error,.busy(0),.ok(0),.error(2'b01));	
				Wait(1);
				write_reg(clk,wr_en,wr_addr,wr_data,.enable(1),.addr(2),.data('b10));
				read_port_b(clk,rd_addr_b,rd_data_b,.addr_b(2));
				// maybe will Fail lines from 198 tp 205 
				if (READ_LATENCY == 1) begin  
					if (rd_data_b == 'b00)
						$display("%0t PASS STICKY Bit Error Check ",$time );
					else 	
				$display("%0t FAIL STICKY Bit Error Check rd_data_b %0b",$time ,rd_data_b);
					end 
				else  
					$display("%0t Ignore STICKY Bit Error Check READ_LATENCY = 0 ",$time );
				Wait(3);
			end 		
		// ===============================
		// Shadow State <Self-Checking>
		// ===============================
			"shadow_state_test": begin
				$display(" ============ shadow_state_test ============ ");
				write_reg(clk,wr_en,wr_addr,wr_data,.enable(1),.addr(1),.data('d4800));
				read_port_a(clk,rd_addr_a,rd_data_a,.addr_a(1));
				Wait(1);
				set_uart_status(clk,uart_busy,update_ok,uart_error,.busy(0),.ok(1),.error(2'b11));	

				Wait(1);
				read_port_a(clk,rd_addr_a,rd_data_a,.addr_a(1));
				if (rd_data_a == 'd4800)
					$display("%0t PASS Shadow State Check ",$time );
				else 	
					$display("%0t FAIL Shadow State Check rd_data_a %0d",$time ,rd_data_a);
			end 
		// ===============================
		// Reserved Register <Self-Checking>/<Negtive-Test>
		// ===============================
			"write_reserved_register":begin 
				$display(" ============ write_reserved_register ============ ");
				write_reg(.clk(clk),.wr_en(wr_en),.wr_addr(wr_addr),.wr_data(wr_data),.enable(1),.addr(2),.data('d01));
				read_port_b(clk,rd_addr_b,rd_data_b,.addr_b(2));
				if (rd_data_b != 'd01)
					$display("%0t PASS Reserved Register Check ",$time );
				else 	
					$display("%0t FAIL hadow Reserved Register rd_data_b %0d",$time ,rd_data_b);
				Wait(5);
			end 
		// ===============================================
		// (Register map Read/Write operations) <Negtive-Test>
		// ===============================================
			"write_negtive_test": begin 
				$display(" ============ write_negtive_test =========== ");
	     		write_reg(clk,wr_en,wr_addr,wr_data,.enable(0),.addr(0),.data('hABC));
				read_port_b(clk,rd_addr_b,rd_data_b,.addr_b(0));
				Wait(10);
				$stop;
			end
			
		endcase 
	end 		
		
endtask 


endpackage 


