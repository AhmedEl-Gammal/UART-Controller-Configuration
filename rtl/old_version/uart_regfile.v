
module uart_regfile #(
parameter DATA_WIDTH = 16,
parameter READ_LATENCY =0,
parameter N_Reg = 4
)(
// Clock/Reset
  input  logic          clk,
  input  logic          rst_n,
  
  // Input Host Interface
  input  logic          wr_en,
  input  logic [$clog2(N_Reg):0]   wr_addr,    	
  input  logic [DATA_WIDTH-1 :0]   wr_data,    	
  input  logic [$clog2(N_Reg):0]   rd_addr_a,  	
  input  logic [$clog2(N_Reg):0]   rd_addr_b, 
  
  // Output Host Interface  
  output logic [DATA_WIDTH-1:0]   rd_data_a,  	
  output logic [DATA_WIDTH-1:0]   rd_data_b,   
  output logic          rd_valid_a,  	
  output logic          rd_valid_b,

  // Input System Interface
  input  logic        uart_busy, 
  input  logic [1:0]  uart_error,  
  input  logic        update_ok, 
  
  // Output System Interface
  output logic          uart_enable,
  output logic [2:0]    uart_mode,
  output logic [15:0]   uart_rate
);

//--- FRD-REG-01 : Register map with 16bits width and number registers 3

// Regfile size 
logic [DATA_WIDTH-1:0] mem [(N_Reg-1):0];

// Shadow Register 
logic [DATA_WIDTH-1:0] shadow_reg;

// Integer for loop generation


// =========================================================================
// WRITE OPERATION
// =========================================================================
//--- FRD-ITF-03: Interface Parameters (DATA_WIDTH ,N_Reg)
//--- FRD-ITF-04: Write occurs on rising edge of clk when wr_en is asserted.
//--- FRD-RTL-01: Synchronous reset to defaults for all registers and shadow state.
//--- FRD-RTL-02: After reset deassertion, all outputs and storage must be known.
//--- FRD-RTL-03: Writes are ignored with no side-effects  when write OOB.
//--- FRD-RTL_06: BAUD write updates shadow; commit to active only on update_ok=1. Reads return active value
//--- FRD-RTL-05: ERROR bit is sticky; software clears by writing 1 (W1C)
//--- FRD-RTL_07: Reset Defaults is the same default value for both shadow and active registers.
//--- FRD-RTL-08: Writes to RO fields or reserved bits have no effect, the stored value remains unchanged.
// Parametrize & sync write with enable & syn_reset & OOB & Shadow-state & Register reserved & Error-bit Clear 
always_ff @(posedge clk) begin
	if (!rst_n) begin
		shadow_reg <= 16'd9600;
		// Initialize all registers to 0
		for (int i=0; i<N_Reg ; i +=1) begin 
			if (i==1) begin 
				// Baud-Rate initial case
				mem[i] <= 16'd9600;
			end 	
			else mem[i] <= 16'b0;
		end
	end	
	else begin 
		// ==================================
		// Update (Baud Rate) Register if update_OK = 1 
		// ==================================
		if (update_ok) begin 
			mem[1] <= shadow_reg;	
		end   
		// ==================================
		// Reserved for software(STATUS Busy) Register and access by only hardware 
		// ==================================
		mem[2][0]  <= uart_busy;
		
		// ==================================
		// Handle Logic (STATUS Error) Register (Sticky bit)  
		// ==================================
		if (uart_error)  begin // FIXME 2bits Error error 
			mem[2][1]  <=1'b1;
		end 
		else if (wr_en && (wr_addr == 2) && wr_data[1])	begin 
			mem[2][1]   <= 1'b0;
		end 
		
		// ==================================
		// Handle another Logic Registers (OOB)  	
		// ==================================
		if (wr_en && (wr_addr < N_Reg)) begin  
			if (wr_addr == 0) begin
				mem[wr_addr] <= wr_data[3:0];
			end 
			else if (wr_addr == 1)   begin  // ----- update shadow_reg  
				shadow_reg <= wr_data; 
			end
		end
	end 
end 

// =========================================================================
// READ OPERATION
// =========================================================================
//--- FRD-ITF-05: when READ_LATENCY=0, perform combinational read at the same cycle.
//--- FRD-RTL-03: Reads to OOB addresses return 0 
//--- FRD-RTL_04: Same-cycle read/write to same address follows the policy where it shall return the newly written value.
logic [DATA_WIDTH-1 : 0]comb_a,comb_b;
logic comb_rd_valid_a, comb_rd_valid_b;

generate
	if (READ_LATENCY == 0) begin : gen_latency_zero
	   // ====================================
	   // PORT A LOGIC (RAW - OOB) Supported
	   // ====================================
		assign rd_data_a = ( (rd_addr_a < N_Reg) && (wr_addr == rd_addr_a) ) ? wr_data : // --- RAW 
							 (rd_addr_a < N_Reg)                             ? mem[rd_addr_a] :     
							                                                   16'b0 ; // --- OOB
						   
		assign rd_valid_a = (rd_addr_a < N_Reg) ? 1'b1 : 1'b0; // --- not determined in FRD

		// ====================================
		// PORT B LOGIC (RAW - OOB) Supported
		// ====================================
		// FIXME SSPACE &TAPS aligment 
		assign rd_data_b = ( (rd_addr_b < N_Reg) && (wr_addr == rd_addr_b) ) ? wr_data : // --- RAW 
		                     (rd_addr_b < N_Reg)                             ? mem[rd_addr_b] : 
							                                                   16'b0 ; // --- OOB
						   
		assign rd_valid_b = (rd_addr_b < N_Reg) ? 1'b1 : 1'b0; // --- not determined in FRD
	end
	else if (READ_LATENCY == 1) begin : gen_latency_nonzero  	
		always_ff @(posedge clk) begin 
			if (!rst_n) begin
				comb_a  <= 16'b0;
				comb_b  <= 16'b0;
				comb_rd_valid_a <= 1'b0;
				comb_rd_valid_b <= 1'b0;
			end 
			
			else begin 
				// ====================================
				// PORT A LOGIC OOB Supported
				// ====================================
				if (rd_addr_a < N_Reg) begin 
					comb_a <= mem[rd_addr_a];
					comb_rd_valid_a <= 1'b1;  // --- not determined in FRD
				end 
				else begin 
					comb_a <= 16'b0;
					comb_rd_valid_a <= 1'b0; // --- not determined in FRD
				end		
				// ====================================
				// PORT B LOGIC OOB Supported
				// ====================================
				if (rd_addr_b < N_Reg) begin 
					comb_b <= mem[rd_addr_b];
					comb_rd_valid_b <= 1'b1;  // --- not determined in FRD
				end 
				else begin 
					comb_b <= 16'b0;
					comb_rd_valid_b <= 1'b0; // --- not determined in FRD
				end		
			end 
		end
	end 
	else begin 
	    $error("Error!READ_LATENCY = %0d must be Range between 0 or 1 only",READ_LATENCY);
	    $fatal("FATAL ERROR,READ_LATENCY = %0d must be Range between 0 or 1 only",READ_LATENCY);
	end 
	assign rd_data_a = comb_a;
	assign rd_data_b = comb_b;
	assign rd_valid_a = comb_rd_valid_a;
	assign rd_valid_b = comb_rd_valid_b;
		
endgenerate

// =========================================================================
// OUTPUT SYSTEM INTERFACE
// =========================================================================
always_comb begin 
	uart_enable <= mem[0][0]; 
	uart_mode   <= mem[0][3:1]; 
	uart_rate   <= mem[1]; 
end 

endmodule 