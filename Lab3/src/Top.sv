module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	input [3:0] i_speed, // design how user can decide mode on your own
	input i_fast,
	input i_slow0,
	input i_slow1,
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ, // write in data or read data // inout 
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,  // I2C setting control  // inout 
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,  // // inout 
	inout  i_AUD_BCLK,  //  // inout 
	inout  i_AUD_DACLRCK,  //  // inout 
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [5:0] o_record_time,
	output [5:0] o_play_time,
	output [2:0] o_state

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 7;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

logic finish_i2c, start_i2c ;
logic [2:0] state_r, state_w;
logic i2c_oen;
wire i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic [15:0] dac_data_r;
logic dsp_play, dsp_pause, dsp_stop ;
logic recd_start, recd_pause, recd_stop ;
logic o_en ;
logic [31:0] recd_time, play_time ;

logic [19:0] counter ;
logic [1:0] prot_r, prot_w ;

assign io_I2C_SDAT = i2c_sdat;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play ;
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input
assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;


assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign dsp_play = (state_r==S_PLAY) ;
assign dsp_pause = (state_r==S_PLAY_PAUSE) ;
assign dsp_stop = !(state_r==S_PLAY) && !(state_r==S_PLAY_PAUSE) ;

assign recd_start = (state_r==S_RECD) ;
assign recd_pause = (state_r==S_RECD_PAUSE) ;
assign recd_stop = !(state_r==S_RECD) && !(state_r==S_RECD_PAUSE) ;

// 12M hz , 8MHZ , 
assign o_record_time[5:0] = recd_time[28:23] ; // recd_time (display/3) => 15, 10s ; 63 , 42s
assign o_play_time[5:0]   = play_time[28:23] ; // play_time (display/3) => 15, 10s ; 63 , 42s
assign o_state = state_r;
// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(start_i2c),
	.o_finished(finish_i2c),
	.o_sclk(o_I2C_SCLK),
	.io_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(dsp_play),
	.i_pause(dsp_pause),
	.i_stop(dsp_stop),
	.i_speed(i_speed),
	.i_fast(i_fast),
	.i_slow_0(i_slow0), // constant interpolation
	.i_slow_1(i_slow1), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play),
	.o_dac_data_ready(o_en)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en((o_en)), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data , io_SRAM_DQ
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_bclk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recd_start),
	// .i_pause(recd_pause),
	.i_stop(recd_pause | recd_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record),
);

always_comb begin
	case(state_r)
	S_I2C  : state_w = (finish_i2c)? S_IDLE : S_I2C ;
	S_IDLE : state_w = (i_key_0)? S_RECD : (i_key_1)? S_PLAY : S_IDLE ;
	S_RECD : state_w = (i_key_0)? S_RECD_PAUSE : (i_key_2)? S_IDLE : S_RECD ;
	S_RECD_PAUSE :  state_w = (i_key_0)? S_RECD : (i_key_2)? S_IDLE : S_RECD_PAUSE ;
	S_PLAY : state_w = (i_key_1)? S_PLAY_PAUSE : (i_key_2)? S_IDLE : S_PLAY ;
	S_PLAY_PAUSE :  state_w = (i_key_1)? S_PLAY : (i_key_2)? S_IDLE : S_PLAY_PAUSE ;
	default : state_w = S_IDLE ;
	endcase
end

always_comb begin
	case(prot_r)
	0 : prot_w = (i_AUD_DACLRCK)? 1 : 2 ;
	1 : prot_w = (i_AUD_DACLRCK)? 1 : 2 ;
	2 : prot_w = (!i_AUD_DACLRCK)? 3 : 0 ;
	3 : prot_w = (!i_AUD_DACLRCK)? 3 : 0 ;
	default : prot_w = 0 ;
	endcase
end

always_ff @(negedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_I2C ;
		start_i2c <= 1 ;
		recd_time <= 0 ;
		play_time <= 0 ;
		dac_data_r <= 0 ;
		counter <= 0 ;
		prot_r <= 0 ;
	end
	else begin
		state_r <= state_w ;
		start_i2c <= 1 ;
		recd_time <= (state_r==S_RECD)? recd_time + 1 : (state_r==S_IDLE)? 0 : recd_time ;
		play_time <= (state_r==S_PLAY)? play_time + 1 : (state_r==S_IDLE)? 0 : play_time ;
		dac_data_r <= dac_data ;
		counter <= (prot_r==2 && dsp_play)? counter + 1 : counter ;
		prot_r <= prot_w ;
	end
end

endmodule
