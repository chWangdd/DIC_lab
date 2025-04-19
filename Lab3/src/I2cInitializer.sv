module I2cInitializer(
    input  i_rst_n,
    input  i_clk,
    input  i_start,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen
);
localparam data_bytes = 30;
localparam [data_bytes * 8-1: 0] setup_data = {
    24'b00110100_000_1001_0_0000_0001,
    24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_0111_0_0100_0010,
    24'b00110100_000_0110_0_0000_0000,
    24'b00110100_000_0101_0_0000_0000,
    24'b00110100_000_0100_0_0001_0101,
    24'b00110100_000_0011_0_0111_1001,
    24'b00110100_000_0010_0_0111_1001,
    24'b00110100_000_0001_0_1001_0111,
    24'b00110100_000_0000_0_1001_0111
};
// the first bit is HIGH  -> transmitting the initialization message
// the second bit is HIGH -> ACK transmission
// the first and the third bit is HIGH -> the SDAT is valid
localparam S_IDLE        = 4'b0000;
localparam S_START       = 4'b0001;
localparam S_GAURD1      = 4'b0100;
localparam S_SEND        = 4'b0101;
localparam S_GUARD2      = 4'b0110;
localparam S_STOP        = 4'b0010;
localparam S_STOP_BUFFER = 4'b1010;
localparam S_FINISH      = 4'b0011;

// ---------- logic assignment --------------
logic [data_bytes * 8 -1: 0] data_r, data_w;
logic [3:0] state_r, state_w;
logic [2:0] bits_cnt_r, bits_cnt_w;
logic [1:0] bytes_cnt_r, bytes_cnt_w;
logic [2:0] stop_cnt_r, stop_cnt_w;
logic finish_r, finish_w, oen_r, oen_w;

// ---------- wires assignment --------------
assign o_sclk = (state_r[2] || state_r == S_STOP_BUFFER)? (state_r[0]) : 1;
assign o_sdat = (state_r == S_IDLE)        ? 1:
                (state_r == S_START)       ? 0:
                (state_r == S_STOP)        ? 0:
                (state_r == S_STOP_BUFFER) ? 0:
                (state_r == S_FINISH)      ? 1:
                (oen_r)                    ? 0: 
                                             data_r[data_bytes * 8 -1];
assign o_finished = finish_r;
assign o_oen = oen_r;

always_comb begin
  state_w = state_r;
  data_w = data_r;
  finish_w = 0;
  oen_w = oen_r;
  case(state_r)
    S_IDLE: begin
      if(i_start) begin
        state_w = S_START;
        data_w = setup_data;
      end else begin
        state_w = state_r;
        data_w = data_r;
      end
      finish_w = 0;
      oen_w = 0;
    end
    S_START: begin 
      state_w = S_GAURD1;
      data_w = data_r;
      finish_w = 0;
      oen_w = 0;
    end
    S_GAURD1: begin
      state_w = S_SEND;
      data_w = data_r;
      finish_w = 0;
      oen_w = oen_r;
    end
    S_SEND: begin
      state_w = S_GUARD2;
      data_w = data_r;
      finish_w = 0;
      oen_w = oen_r;
    end
    S_GUARD2: begin
      if (bytes_cnt_r == 0 && oen_r) begin // finish 3 times ACK transmission
        state_w = S_STOP_BUFFER;
        data_w = data_r << 1;
        oen_w = 0;
      end else if (bytes_cnt_r > 0 && oen_r) begin // finish the transmission of ACK
        state_w = S_GAURD1;
        data_w = data_r << 1;
        oen_w = 0;
      end else if (bits_cnt_r == 0) begin // start to send ACK
        state_w = S_GAURD1;
        data_w = data_r;
        oen_w = 1;
      end else begin
        state_w = S_GAURD1;
        data_w = data_r << 1;
        oen_w = 0;
      end
      finish_w = 0;
    end
    S_STOP_BUFFER: begin
      state_w = S_STOP;
      data_w = data_r;
      finish_w = 0;
      oen_w = 0;
    end
    S_STOP: begin
      if(data_r == 0) begin
        state_w = S_FINISH;
        finish_w = 1;
      end else begin
        state_w = S_FINISH;
        finish_w = 0;
      end
      data_w = data_r;
    end
    S_FINISH: begin
      if(data_r != 0 && stop_cnt_r == 0)
        state_w = S_START;
      else
        state_w = state_r;
      data_w = data_r;
      finish_w = 0;
    end
  endcase
end


always @(*) begin
  if (state_r == S_STOP_BUFFER)
    stop_cnt_w = 3;
  else if (state_r == S_FINISH)
    stop_cnt_w = stop_cnt_r - 1;
  else
    stop_cnt_w = stop_cnt_r;
end

// bytes counter counts down from 2 
always @(*) begin 
  if (state_r == S_START)
    bytes_cnt_w = 2;
  else if (state_r == S_GUARD2 && oen_r)
    bytes_cnt_w = bytes_cnt_r - 1;
  else 
    bytes_cnt_w = bytes_cnt_r;
end

// bits counter counts down from 7
always @(*) begin 
  if (state_r == S_START)
    bits_cnt_w = 7;
  else if (state_r == S_GUARD2 && !oen_r)
    bits_cnt_w = bits_cnt_r - 1;
  else 
    bits_cnt_w = bits_cnt_r;
end

// sequential block
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		state_r <= S_IDLE;
		data_r <= setup_data;
    bytes_cnt_r <= 0;
    stop_cnt_r <= 0;
    bits_cnt_r <= 0;
		finish_r <= 0;
    oen_r <= 0;
	end else begin
		state_r <= state_w;
		data_r <= data_w;
    bytes_cnt_r <= bytes_cnt_w;
    stop_cnt_r <= stop_cnt_w;
    bits_cnt_r <= bits_cnt_w;
		finish_r <= finish_w;
    oen_r <= oen_w;
	end
end
endmodule