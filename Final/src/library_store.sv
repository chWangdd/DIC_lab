module library_store(
	input  i_clk, 
	input  i_rst_n,
	input  [4:0]i_x,
	input  [4:0]i_y,
	input  i_deny, 
	input  i_start, 
	input  i_valid, 
	output [4:0] o_x,
	output [4:0] o_y, 
	output [19:0] o_addr
);

logic [1:0] state_r, state_w;
logic [4:0] addr_r , addr_w;

localparam IDLE = 2'd0, 
		   WORK = 2'd1;
		   
logic [10:0] counter_r, counter_w;

localparam LIMIT = 5'b1_1010;
localparam UNIT  = 11'b100_0000_0000;
localparam UNTOUCHABLE = 15'b110_1100_0000_0000;

always@(*)begin: FSM
	state_w = state_r;
	case(state_r)
		IDLE: begin
			state_w = (i_start) ? WORK : IDLE;
		end
		WORK: begin
			state_w = (!i_deny)  ? IDLE : WORK; 
		end
	endcase
end

assign o_x    = ((state_r == WORK) && (i_valid)) ? i_x : i_x;
assign o_y    = ((state_r == WORK) && (i_valid)) ? i_y : i_x;
assign o_addr = (state_r == WORK) ? {4'b0, addr_r, counter_r} : UNTOUCHABLE;

assign counter_w = (state_r == IDLE) ? 0 : (i_valid) ? counter_r + 1 : counter_r;

assign addr_w    = ((state_r == WORK) && (!i_deny)) ? ((addr_r == LIMIT - 1) ? 0 : addr_r + 1) : addr_r;

always@(negedge i_rst_n or posedge i_clk)begin: Flip_Flop
	if(!i_rst_n)begin
		state_r   <= IDLE;
		addr_r    <= 0;
		counter_r <= 0;
	end
	else begin
		state_r   <= state_w;
		addr_r    <= addr_w;
		counter_r <= counter_w;
	end
end

endmodule