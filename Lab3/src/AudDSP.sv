module AudDSP (
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,
	input [3:0]i_speed,
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	input i_daclrck,
	input  [15:0]i_sram_data,
	output [15:0]o_dac_data,
	output [19:0]o_sram_addr
    output o_dac_data_ready
);

parameter S_idle = 0 ;
parameter S_fast = 1 ;
parameter S_slow0= 2 ;
parameter S_slow1= 3 ;
parameter S_fastp= 4 ;
parameter S_slow0p= 6 ;
parameter S_slow1p= 7 ;

logic [2:0] state_r, state_w ;
logic [3:0]speed;
logic [19:0]addr_r, addr_w;
logic [3:0] sample_period;
logic signed[15:0] former_data;
logic signed[15:0] current_data;
logic signed[15:0] interpolation_r, interpolation_w ;
logic signed[15:0] calculate ;
logic ready ;
logic [3:0] counter ;
logic wait16;


assign o_dac_data = interpolation_r ;
assign o_sram_addr = addr_r ;
assign o_dac_data_ready = wait16 ;
assign wait16 = (counter==15) ;

always_comb begin
	case(state_r)
	S_idle  : state_w = (i_start)? ((i_fast)?S_fast:(i_slow_0)?S_slow0:(i_slow_1)?S_slow1:S_idle) : S_idle ;

	S_fast  : state_w = (i_stop)? S_idle : (i_pause)? S_fastp : S_fast ;
	S_slow0 : state_w = (i_stop)? S_idle : (i_pause)? S_slow0p : S_slow0 ;
	S_slow1 : state_w = (i_stop)? S_idle : (i_pause)? S_slow1p : S_slow1 ;

    S_fastp : state_w = (i_stop)? S_idle : (i_start)? S_fast  : S_fastp ;
    S_slow0p: state_w = (i_stop)? S_idle : (i_start)? S_slow0 : S_slow0p ;
    S_slow1p: state_w = (i_stop)? S_idle : (i_start)? S_slow1 : S_slow1p ;
	default : state_w = S_idle ;
	endcase
end

always_comb begin
	case(state_r)
	S_idle  : addr_w = 0 ;

	S_fast  : addr_w = (wait16)? addr_r + speed : addr_r ;
	S_slow0 : addr_w = (sample_period==speed)? addr_r + 1 : addr_r ;
	S_slow1 : addr_w = (sample_period==speed)? addr_r + 1 : addr_r ;

    S_fastp : addr_w = addr_r ;
    S_slow0p: addr_w = addr_r ;
    S_slow1p: addr_w = addr_r ;
	default : addr_w = 0 ;
	endcase
end


always_comb begin
	case(state_r)
	S_idle  : interpolation_w = 0 ;

	S_fast  : interpolation_w = current_data ;
	S_slow0 : interpolation_w = (sample_period==speed)? current_data : former_data  ;
	S_slow1 : interpolation_w = (counter==speed)? current_data : calculate ;

    S_fastp : interpolation_w = 0 ;
    S_slow0p: interpolation_w = 0 ;
    S_slow1p: interpolation_w = 0 ;
	default : interpolation_w = 0 ;
	endcase
end

always_comb begin
    speed = i_speed ;
    calculate = ( ( $signed({1'b0,sample_period-4'd0}) * former_data ) + ( $signed({1'b0,speed-sample_period}) * current_data ) ) / speed ;
end

always_ff begin
    if(!i_rst_n) begin
        sample_period <= 0 ;
        former_data <= 0 ;
        current_data <= 0 ;
        addr_r <= 0 ;
        counter <= 0 ;
        interpolation_r <= 0 ;
    end
    else begin
        sample_period <= (sample_period==speed)? 0 : (wait16)? sample_period + 1 : sample_period ;
        former_data <= (wait16)? current_data : former_data ;
        current_data <= (wait16)? i_sram_data : current_data ;
        addr_r <= addr_w ;
        counter <= counter + 1 ;
        interpolation_r <= interpolation_w ;
    end
end



endmodule