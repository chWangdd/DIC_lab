module AudPlayer(
	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, 
	input [15:0] i_dac_data, 
	output o_aud_dacdat
); 

// design the FSM and states as you like
parameter S_IDLE       = 2'd0;
parameter S_OUT        = 2'd1;
parameter S_HOLD       = 2'd3;

logic [1:0] state_r, state_w;
logic [3:0] counter_r, counter_w;
logic [15:0] dac_in_r, dac_in_w;
logic AUD_OUT_r, AUD_OUT_w;

assign dac_in_w = (i_en) ? i_dac_data : dac_in_r;
assign o_aud_dacdat = AUD_OUT_r;

always_comb begin
	// design your control here
	state_w = state_r;
	counter_w = counter_r;
	AUD_OUT_w = AUD_OUT_r;
	case(state_r)
		S_IDLE: begin
			if(i_daclrck)begin
				state_w = S_OUT;
				counter_w = 14;
				AUD_OUT_w = dac_in_r[15];
			end
			else begin
				state_w = S_IDLE;
				counter_w = 0;
				AUD_OUT_w = 0;
			end
		end
		S_OUT: begin
			if(counter_r == 0)begin
				state_w = S_HOLD;
				counter_w = 0;
				AUD_OUT_w = dac_in_r[counter_r];
			end
			else begin
				state_w = S_OUT;
				counter_w = counter_r - 1;
				AUD_OUT_w = dac_in_r[counter_r];
			end
		end
		S_HOLD: begin
			state_w = (!i_daclrck) ? S_IDLE : S_HOLD;
			counter_w = 0;
			AUD_OUT_w = 0;
		end
	endcase
end

always_ff @(posedge i_bclk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_IDLE;
		counter_r <= 0;
		dac_in_r <= 0;
		AUD_OUT_r <= 0;
	end
	else begin
		state_r <= state_w;
		counter_r <= counter_w;
		dac_in_r <= dac_in_w;
		AUD_OUT_r <= AUD_OUT_w;
	end
end

endmodule
