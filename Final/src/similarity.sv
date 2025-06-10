module similarity(
	input i_clk, 
	input i_rst_n,
	input i_valid, // real time 60 fps valid vector signals
	input [8:0] i_index, 
	input [5:0] vector_x,
	input [5:0] vector_y,
	input [5:0] lib_x, 
	input [5:0] lib_y, 
	output o_valid, 
	output o_index
);

logic [1:0] state_r, state_w;
logic [8:0] counter_r, counter_w;
logic signed [5:0] VEC_X, VEC_Y;
logic signed [5:0] LIB_X, LIB_Y;
logic [4:0] max_r, max_w;
logic signed [15:0] max_sum_r, max_sum_w;
logic signed [15:0] inter_r, inter_w;

localparam IDLE = 2'b00, 
		   WORK = 2'b01, 
		   OUT  = 2'b11;;

assign VEC_X = vector_x;
assign VEC_Y = vector_y;
assign LIB_X = lib_x;
assign LIB_Y = lib_y;

assign o_valid = (state_r == OUT);
assign o_index = max_r;

always@(*)begin: INTERMEDIATE
	inter_w = inter_r;
	if((state_r == IDLE) && (i_valid))begin	
		inter_w = VEC_X * LIB_X + VEC_Y * LIB_Y;
	end
	else if(state_r == WORK)begin
		if(counter_r[8:4])begin
			if(!counter[3:0])begin
				inter_w = VEC_X * LIB_X + VEC_Y + LIB_Y;
			end
			else begin
				inter_w = inter_r + VEC_X * LIB_X + VEC_Y + LIB_Y;
			end
		end
		else begin
			inter_w = inter_r + VEC_X * LIB_X + VEC_Y + LIB_Y;
		end
	end
end

always@(*)begin: MAX_OUT
	max_w = max_r;
	max_sum_w = max_sum_r;
	if(state_r == IDLE)begin
		max_w = 0;
		max_sum_w = 0;
	end
	else if(state_r == WORK)begin
		if(counter_r && (!counter[3:0]))begin
			max_sum_w = (max_sum_r < inter_r) ? inter_r      : max_sum_r;
			max_w     = (max_sum_r < inter_r) ? counter[8:4] : max_r;
		end
	end
end

always@(*)begin: FSM
	state_w = state_r;
	case(state_r)
		IDLE: begin
			state_w = (i_valid) ? WORK : IDLE;
		end
		WORK: begin
			state_w = (counter_r == 9'd416) ? OUT : WORK;
		end
		OUT: begin
			state_w = IDLE;
		end
	endcase
end

always@(*)begin: Counter
	counter_w = (state_r == WORK) ? counter_r + 1 : counter_r;
end

always@(negedge i_rst_n or posedge i_clk)begin: FF
	if(!i_rst_n)begin
		state_r    <= IDLE;
		counter_r  <= 0;
		max_r      <= 0;
		max_sum_r  <= 0;
		inter_r    <= 0;
	end
	else begin
		state_r    <= state_w;
		counter_r  <= counter_w;
		max_r      <= max_w;
		max_sum_r  <= max_sum_w;
		inter_r    <= inter_w;
	end
end

endmodule