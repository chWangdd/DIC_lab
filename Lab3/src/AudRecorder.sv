//*****************The design utilizes right channel************************//
module AudRecorder(
	input i_rst_n,
	input i_bclk,
	input i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data
); 

// design the FSM and states as you like
parameter S_IDLE       		= 3'd0;
parameter S_READ      	    = 3'd1;
parameter S_PAUSE_READ      = 3'd5;
parameter S_HOLD      		= 3'd3;
parameter S_PAUSE_HOLD		= 3'd7;

logic [2:0]  state_r, state_w;
logic [3:0]  counter_r, counter_w;
logic [15:0] data_out_r, data_out_w;
logic [19:0] ADDR_r, ADDR_w;
logic changed_r, changed_w;

assign o_data = data_out_r;
assign o_address = ADDR_r;

always_comb begin
	state_w = state_r;
	counter_w = counter_r;
	data_out_w = data_out_r;
	ADDR_w = ADDR_r;
	changed_w = 0;
	case(state_r)
		S_IDLE: begin
			if(i_start)begin
				state_w = S_READ;
				counter_w = 15;
				data_out_w = 0;
				ADDR_w = ADDR_r;
			end
		end
		S_READ: begin
			if(i_stop)begin
				state_w = S_IDLE;
				counter_w = 0;
				data_out_w = data_out_r;
				ADDR_w = ADDR_r;
			end
			else if(i_pause)begin
				state_w = S_PAUSE_READ;
				counter_w = counter_r;
				data_out_w = data_out_r;
				ADDR_w = ADDR_r;
			end
			else if(i_lrc)begin
				state_w = (counter_r == 0) ? S_HOLD : S_READ;
				counter_w = (counter_r == 0) ? 0 : counter_r - 1;
				data_out_w = data_out_r;
				data_out_w[counter_r] = i_data;
				ADDR_w = ADDR_r;
			end
			else begin
				state_w = S_HOLD;
				counter_w = 0;
				data_out_w = data_out_r;
				ADDR_w = ADDR_r;
			end
		end
		S_PAUSE_READ: begin
			if(i_stop)begin
				state_w = S_IDLE;
				counter_w = 0;
			end
			else if(i_start || i_pause)begin
				state_w = S_READ;
			end
		end
		S_HOLD: begin
			changed_w = changed_r;
			if(i_stop)begin
				state_w = S_IDLE;
			end
			else if(i_pause)begin
				state_w = S_PAUSE_HOLD;
			end
			else if(!i_lrc && !changed_r)begin
				ADDR_w = ADDR_r + 1;
				data_out_w = 0;
				changed_w = 1;
			end
			else if(i_lrc && changed_r)begin
				state_w = S_READ;
				data_out_w = 0;
				ADDR_w = ADDR_r;
				counter_w = 15;
			end
		end
		S_PAUSE_HOLD: begin
			changed_w = changed_r;
			if(i_stop)begin
				state_w = S_IDLE;
			end
			else if(i_start || i_pause)begin
				state_w =S_HOLD;
			end
		end
	endcase
end

always_ff @(negedge i_bclk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r 	<= S_IDLE;
		counter_r	<= 0;
		data_out_r 	<= 0;
		ADDR_r 		<= 0;
		changed_r   <= 0;
	end
	else begin
		state_r 	<= state_w;
		counter_r 	<= counter_w;
		data_out_r 	<= data_out_w;
		ADDR_r 		<= ADDR_w;
		changed_r   <= changed_w;
	end
end

endmodule
