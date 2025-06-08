//******* VER_1 *********//
//******* 0609  *********//
module SRAM_Controller(

i_clk,
i_rst,
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

input  i_clk;
input  i_rst;
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
logic [2:0]  state_r, state_w;
logic [15:0] IN_DATA_w, IN_DATA_r;
logic [19:0] IN_ADDR_w, IN_ADDR_r;
logic [15:0] DATA_BACK_r, DATA_BACK_w;

localparam IDLE        = 3'b000, 
		   READ        = 3'b001,
		   READ_BACK   = 3'b011,
		   WRITE       = 3'b010,
		   WRITE_BACK  = 3'b110;
		   
localparam LIMIT = 4'b0111;

assign o_SRAM_CE_N = 1'b0 ;
assign o_SRAM_OE_N = 1'b0 ;
assign o_SRAM_LB_N = 1'b0 ;
assign o_SRAM_UB_N = 1'b0 ;

always@(*)begin: FSM
	state_w = state_r;
	case(state_r)
		IDLE: begin
			if(core_mem_request)begin
				state_w = (core_mem_wr) ? READ : WRTIE;
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
	endcase
end

always@(*)begin: Counter_Assignment
	counter_w = (state_r) ? ((counter_r == LIMIT) ? 0 : counter_r + 1) : 0;
end

always@(*)begin: Input_Capture
	IN_DATA_w = (core_mem_request) ? core_mem_r_value : IN_DATA_r;
	IN_ADDR_w = (core_mem_request) ? core_mem_addr    : IN_ADDR_r;
end

assign o_SRAM_ADDR  = (core_mem_request) ? core_mem_addr : IN_ADDR_r;
assign io_SRAM_DQ   = (state_r == WRITE) ? IN_DATA_r     :     16'dz;
assign o_SRAM_WE_N  = (state_r == WRITE) ? 1'b0          :     	1'b1;

assign core_mem_r_value = DATA_BACK_r;
assign DATA_BACK_w      = (state_r == READ)  ? io_SRAM_DQ: DATA_BACK_r;   
assign core_wait        = ((state_r == READ) || (state_r == WRITE));

always@(posedge i_clk or negedge i_rst)begin: Flip_Flop
	if(!i_rst)begin
		state_r   	<= IDLE;
		counter_r 	<= 0;
		IN_DATA_r 	<= 0;
		IN_ADDR_r   <= 0;
		DATA_BACK_r <= 0;
	end
	else begin
		state_r   	<= state_w;
		counter_r 	<= counter_w;
		IN_DATA_r 	<= IN_DATA_w;
		IN_ADDR_r 	<= IN_ADDR_w;
		DATA_BACK_r <= DATA_BACK_w;
	end
end
  
endmodule