module regfile6
#(
  parameter int DATA_WIDTH  	= 16,             	
  parameter int N_REGS   	    = 4, 
  parameter int ADDR_WIDTH      = $clog2(N_REGS),    
  parameter int READ_LATENCY    = 0    // 0: Comb read 1: Registered read	
)
(
  // Clock/Reset
  input  logic          clk ,       // Clock signal
  input  logic          rst_n,     // Active-low synchronous reset
  
  // Host Interface
  input  logic                              wr_en,        						//Write enable
  input  logic [ADDR_WIDTH-1:0] 	        wr_addr,     					   //Write address 
  input  logic [DATA_WIDTH-1:0]             wr_data,    					  // Write data  
  input  logic [ADDR_WIDTH-1:0] 	        rd_addr_a, 		                 // read address port a	
  input  logic [ADDR_WIDTH-1:0] 	        rd_addr_b,		                // read address port b
 	
  output logic [DATA_WIDTH-1:0]             rd_data_a,  	      // read data port a 
  output logic [DATA_WIDTH-1:0]             rd_data_b,           // read data port b
  output logic                              rd_valid_a,		    // Read data valid on  port A  
  output logic                              rd_valid_b,        // Read data valid on  port b

  // System Interface
  input  logic     	  uart_busy, 			 // system busy signal
  input  logic 	      uart_error, 		    // System error signal
  input  logic 	      update_ok, 	       // UART in Idle state

  output logic          uart_enable,     // system enable
  output logic [2:0]    uart_mode,      // system mode
  output logic [15:0]   uart_rate      //Active rate
);

logic [DATA_WIDTH-1:0] mem [0:N_REGS-1] ;
logic [DATA_WIDTH-1:0] a_comb, b_comb;
// Shadow Register 
logic [DATA_WIDTH-1:0] shadow_reg;

//============================================//
  
// Sticky ERROR bit
  logic status_error = 1'b0;           // Default value  
  
// Register map constants
  localparam STATUS_ADDR = 2;
  localparam ERROR_BIT   = 1;
  localparam BUSY_BIT    = 0;
  

always_ff @(posedge clk) begin

	if (!rst_n) begin
		// Initialize all registers to 0
		for (int i=0; i <N_REGS ; i +=1) begin 
			if (i==1) begin 
				// Baud-Rate initial case
				mem[i] <= 'b0010010110000000;
				shadow_reg <= 'b0010010110000000;
			end 	
			else mem[i] <= 'b0;
		end
	end	
	else begin
	
	if (update_ok) 
		mem[1] <= shadow_reg;	
	
      // ========== Hardware error set ==========
      if (uart_error) begin
        status_error <= 1'b1;  // Set sticky error
      end
      // ========== Writes to STATUS register ==========
      if (wr_en && (wr_addr == STATUS_ADDR) && wr_data[ERROR_BIT] ) begin
        // ERROR bit (bit 1): W1C
          status_error <= 1'b0;  // Clear on write 1
        end
	if (wr_en && (wr_addr < N_REGS)) begin  
		if (wr_addr == 1) 
			shadow_reg <= wr_data;	// ----- update shadow_reg 
		else if (wr_addr == STATUS_ADDR)   
			 mem[wr_addr][DATA_WIDTH-1:2] <= wr_data[DATA_WIDTH-1:2]; // ----- (0,1)=(Busy,Error) 
		else // ----- Standard Write
			mem[wr_addr] <= wr_data;
		end 
	// Override with hardware-controlled bits
    mem[STATUS_ADDR][ERROR_BIT] <= status_error;  // Sticky ERROR (W1C)
    mem[STATUS_ADDR][BUSY_BIT]  <= uart_busy;     // BUSY (read-only)
    end    
   
  end 
 
  
  // ========== READ LOGIC WITH OOB PROTECTION and RAW ==========
 // FRD‑RTL-03: Reads to OOB addresses return 0
//FRD‑RTL-04: Same‑cycle read/write to same address return the newly written value.    
  // ========== PORT A ==========
  
always_comb begin 
	a_comb = '0; // default
    b_comb = '0;
	if (rd_addr_a < N_REGS) begin
    // Valid address
    if (wr_en && (wr_addr < N_REGS) && (wr_addr == rd_addr_a)) begin
      // RAW hazard
      a_comb = wr_data;
    end
    else begin
      // No RAW hazard
      a_comb = mem[rd_addr_a];
    end
  end
  
  // ========== PORT B ==========
  if (rd_addr_b < N_REGS) begin
    // Valid address
    if (wr_en && (wr_addr < N_REGS) && (wr_addr == rd_addr_b)) begin
      // RAW hazard
      b_comb = wr_data;
    end
    else begin
      // No RAW hazard
      b_comb = mem[rd_addr_b];
    end
  end
  
end  
// Generate block for latency handling
	generate
    	if (READ_LATENCY == 0) begin
        	assign rd_data_a = a_comb;
        	assign rd_data_b = b_comb;
        	assign rd_valid_a = 1'b1;
        	assign rd_valid_b = 1'b1;
    	end else begin
        	always_ff @(posedge clk) begin
            	if (!rst_n) begin
                	    rd_data_a <= '0;
                	    rd_data_b <= '0;
                	    rd_valid_a <= 1'b0;
                	    rd_valid_b <= 1'b0;
            	end else begin
                	    rd_data_a <= a_comb;
                	    rd_data_b <= b_comb;
                	    rd_valid_a <= 1'b1;
                	    rd_valid_b <= 1'b1;
            	end
        	end
    	end
	endgenerate

 // ========== UART OUTPUTS ==========
  assign uart_enable = mem[0][0];
  assign uart_mode   = mem[0][3:1];
  assign uart_rate   = mem[1];
// Override with hardware-controlled bits
  //  assign mem[STATUS_ADDR][ERROR_BIT] = status_error;  // Sticky ERROR (W1C)
    //assign mem[STATUS_ADDR][BUSY_BIT]  = uart_busy;     // BUSY (read-only)
endmodule

