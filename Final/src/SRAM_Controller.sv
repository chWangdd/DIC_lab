//******* VER_1 *********//
//*******  0609  ********//
//*******  1959  ********//

module SRAM_Controller(

i_clk,
i_rst_n,
mem_valid, 
// Input assignment
core_mem_w_value, 
core_mem_addr,
core_mem_wr,
core_mem_request,
	
// Output
core_mem_r_value,
core_wait,
o_SRAM_ADDR,
o_SRAM_WE_N,
o_SRAM_CE_N,
o_SRAM_OE_N,
o_SRAM_LB_N,
o_SRAM_UB_N,
	
// Inout
io_SRAM_DQ
);

input i_clk;
input i_rst_n;
input mem_valid; 
// Pins to Top Module 
input  core_mem_w_value [15:0];
input  core_mem_addr    [19:0];
input  core_mem_wr  	 	  ;
input  core_mem_request       ;

output core_mem_r_value [15:0];
output core_wait              ;

// Pins to SRAM
output o_SRAM_ADDR      [19:0];

output o_SRAM_WE_N;
output o_SRAM_CE_N;
output o_SRAM_OE_N;
output o_SRAM_LB_N;
output o_SRAM_UB_N;

inout io_SRAM_DQ		[15:0];

logic [3:0]  counter_r, counter_w;
logic [8:0]  addr_count_r, addr_count_w;
logic [2:0]  state_r, state_w;
logic [15:0] IN_DATA_w, IN_DATA_r;
logic [19:0] IN_ADDR_w, IN_ADDR_r;
logic [15:0] DATA_BACK_r, DATA_BACK_w;

localparam IDLE        = 3'b000, 
		   READ        = 3'b001,
		   READ_BACK   = 3'b011,
		   WRITE       = 3'b010,
		   WRITE_BACK  = 3'b110, 
		   RECOG_CTRL  = 3'b100;
		   
localparam LIMIT = 4'b0111; // limit as mem access latency
localparam LetterNum = 9'd416;

assign o_SRAM_CE_N = 1'b0 ;
assign o_SRAM_OE_N = 1'b0 ;
assign o_SRAM_LB_N = 1'b0 ;
assign o_SRAM_UB_N = 1'b0 ;

assign mem_valid = ((state_r == READ_BACK) || (state_r == WRITE_BACK) || ((state_r == RECOG_CTRL) && (counter_r == LIMIT + 1)));
assign addr_count_w = ((state_r == RECOG_CTRL) && (addr_count_r < LetterNum) && (counter_r == LIMIT + 1)) ? addr_count_r + 1 : 0;

always@(*)begin: FSM
	state_w = state_r;
	case(state_r)
		IDLE: begin
			if(core_mem_request)begin
				state_w = (core_mem_wr) ? READ : WRITE;
			end
			else if(inputtimming)begin
				state_w = RECOG_CTRL;
			end
		end
		READ: begin
			state_w = (counter_r == LIMIT) ? READ_BACK : READ;
		end
		WRITE: begin
			state_w = (counter_r == LIMIT) ? WRITE_BACK : WRITE;
		end
		READ_BACK: begin
			state_w = IDLE;
		end
		WRITE_BACK: begin
			state_w = IDLE;
		end
		RECOG_CTRL: begin
			state_w = (addr_count_r == LetterNum) ? IDLE : RECOG_CTRL;
		end
	endcase
end

always@(*)begin: Counter_Assignment
	counter_w = counter_r;
	if(state_r == PROCESS)begin
		counter_w = (counter_r == LIMIT + 1) ? 0 : counter_r + 1;
	end
	else begin
		counter_w = (state_r) ? ((counter_r == LIMIT) ? 0 : counter_r + 1) : 0;
	end
end

always@(*)begin: Input_Capture
	IN_DATA_w = (core_mem_request) ? core_mem_r_value : IN_DATA_r;
	IN_ADDR_w = (core_mem_request) ? core_mem_addr    : IN_ADDR_r;
end

assign o_SRAM_ADDR  = (core_mem_request) ? core_mem_addr : (state_r == RECOG_CTRL) ? {11'b0, addr_count_r} : IN_ADDR_r;
assign io_SRAM_DQ   = (state_r == WRITE) ? IN_DATA_r     :     16'dz;
assign o_SRAM_WE_N  = (state_r == WRITE) ? 1'b0          :     	1'b1;

assign core_mem_r_value = DATA_BACK_r;
assign DATA_BACK_w      = ((state_r == READ) || (state_r == RECOG_CTRL))  ? io_SRAM_DQ: DATA_BACK_r;   
assign core_wait        = ((state_r == READ) || (state_r == WRITE) || ((state_r == RECOG_CTRL) && (counter_r <= LIMIT)));

always@(posedge i_clk or negedge i_rst_n)begin: Flip_Flop
	if(!i_rst_n)begin
		state_r   	 <= IDLE;
		counter_r 	 <= 0;
		IN_DATA_r 	 <= 0;
		IN_ADDR_r    <= 0;
		DATA_BACK_r  <= 0;
		addr_count_r <= 0;
	end
	else begin
		state_r   	 <= state_w;
		counter_r 	 <= counter_w;
		IN_DATA_r 	 <= IN_DATA_w;
		IN_ADDR_r 	 <= IN_ADDR_w;
		DATA_BACK_r  <= DATA_BACK_w;
		addr_count_r <= addr_count_w;
	end
end
  
endmodule