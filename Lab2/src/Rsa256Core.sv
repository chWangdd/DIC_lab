module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);
// parameter a_constant = 256'hc6b662ecb173c53cc7bb4212057f9c0ba283e000b98c9dcf5feaee7d6c933dfb ;
// parameter d_constant = 256'hB6ACE0B14720169839B15FD13326CF1A1829BEAFC37BB937BEC8802FBCF46BD9 ;
// parameter n_constant = 256'hCA3586E7EA485F3B0A222A4C79F7DD12E85388ECCDEE4035940D774C029CF831 ;

// paramter  answer     = 256'h005468652076616c7565206f662050492069733a0a332e313431353932363533 ;
logic [255:0] test_input_t, test_input_d, test_input_n ;
logic [255:0] read_t, read_d, read_n ;
logic mont_f ;
logic expsqr_f;
logic [1:0] state_r, state_w;

logic [255:0] i_t;
logic start_expo_by_sqr ;
logic expo_by_sqr ;
logic [255:0] decrypt ;

assign o_a_pow_d = decrypt ;
assign o_finished =  expsqr_f;

MoP mop(
.rst(i_rst),
.clk(i_clk), 
.Divisor_N(i_n),
.Multipiler(i_a), 
.curr_state(state_r),
.Modulo_m(i_t),
.MoP_Done(start_expo_by_sqr)
);

always_comb begin
	state_w = 0 ;
	case(state_r)
	0 : state_w = (i_start)? 1 : 0 ;
	1 : state_w = (start_expo_by_sqr)? 0 : 1 ;
	2 : state_w = 0 ;
	3 : state_w = 0 ;
	endcase
end

always_comb begin
	read_t = (start_expo_by_sqr)? i_t : test_input_t ;
	read_d = (i_start)? i_d : test_input_d  ;
	read_n = (i_start)? i_n : test_input_n  ;
end
EXPO_by_SQR expo_sqr(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_start(expo_by_sqr),
    .i_a(test_input_t), 
    .i_d(test_input_d),
    .i_n(test_input_n),
    .finish_expsqr(expsqr_f),
	.finish_all(decrypt)
);
// operations for RSA256 decryption
// namely, the Montgomery algorithm
always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst)  state_r <= 0 ;
	else state_r <= state_w ;
end
always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst)  begin
		test_input_t <= 0 ;
		test_input_d <= 0 ;
		test_input_n <= 0 ;
		expo_by_sqr <= 0 ;
	end
	else begin
		test_input_t <= read_t ;
		test_input_d <= read_d ;
		test_input_n <= read_n ;
		expo_by_sqr <= start_expo_by_sqr ;
	end
end

endmodule


module EXPO_by_SQR(
	input i_clk,
	input i_rst,
	input i_start,
	input [255:0] i_a, 
	input [255:0] i_d,
	input [255:0] i_n,
	output finish_expsqr,
	output [255:0] finish_all
);
logic [255:0] t_r, t_w;
logic [255:0] m_r, m_w;
logic [255:0] m_mul_t ;
logic [255:0] t_mul_t ;
logic [255:0] d, n;
logic [7:0] counter_r, counter_w;
logic [7:0] delay_counter ;
logic finish_signal_r;
logic finish_mont1 ;
logic finish_mont2 ;
logic start_mont ;
logic stay_start;

assign finish_expsqr = finish_signal_r && (counter_r==0) ; 
assign finish_all = m_r ;

always_comb begin
    counter_w = (i_start || stay_start)? 0 : (finish_mont1 | finish_mont2)? counter_r + 1 : counter_r ;
end


always_comb begin
	m_w = (i_start)? 256'd1 :(stay_start)? m_r : (d[counter_r]==1 && finish_mont1)? m_mul_t : m_r ;
	t_w = (i_start)? i_a    :(stay_start)? t_r : (finish_mont2)? t_mul_t : t_r ;
end


Mont m_mul_t_mod_n( .i_N(n), .i_a(m_r), .i_b(t_r) , .output_mod(m_mul_t) , .mont_finish(finish_mont1) , .i_clk(i_clk) , .i_rst(i_rst) , .i_start(i_start) );
Mont t_mul_t_mod_n( .i_N(n), .i_a(t_r), .i_b(t_r) , .output_mod(t_mul_t) , .mont_finish(finish_mont2) , .i_clk(i_clk) , .i_rst(i_rst) , .i_start(i_start) );

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		counter_r <= 0 ;
		delay_counter <= 0 ;
		t_r <= 0 ;
		m_r <= 0 ;
		finish_signal_r <= 0 ;
		stay_start <= 0 ;
		n <= 0 ;
		d <= 0 ;
	end
	else begin
		counter_r <= counter_w ;
		delay_counter <= counter_r ;
		t_r <= t_w ;
		m_r <= m_w ;
		finish_signal_r <= (counter_r==8'd255)? 1 : 0 ;
		stay_start <= i_start ;
		n <= (i_start)? i_n : n  ;
		d <= (i_start)? i_d : d  ;
	end
end

endmodule


module Mont(
	input  [255:0] i_N, // cipher text y
	input  [255:0] i_a, // private key
	input  [255:0] i_b,
	output [255:0] output_mod,
	output mont_finish,
	input  i_clk,
	input  i_rst,
	input  i_start
);
integer  i;

logic [256:0] m_r, m_w;
logic [7:0] mont_counter_r, mont_counter_w;
logic finish_one_task ; 

logic [257:0] temp1;
logic [257:0] temp2;
logic plus_logic ;
logic odd_logic ;
logic one_more_time ;
logic [1:0]state_r, state_w ;

assign plus_logic = (i_a[mont_counter_r]==1) ; 
assign odd_logic  = (temp1[0]==1) ; 

assign mont_finish = finish_one_task ;
assign output_mod = m_r[255:0] ;


always_comb begin
	mont_counter_w = (i_start || state_r==1)? 0 : mont_counter_r + 1 ;
end
always_comb begin
	state_w = 0 ;
	case(state_r)
	0 :    state_w = (mont_counter_r==255)? 1 : 0 ;
	1 :    state_w = 2 ;
	2 :    state_w = 0 ;
	3 :    state_w = 0 ;
	endcase
end

always_comb begin
	temp1 = (plus_logic)? m_r+i_b : m_r ;
	temp2 = (odd_logic)? temp1+i_N : temp1 ;
	m_w = (state_r==1)? m_r : (mont_counter_r==255)? ((temp2[257:1]>{1'b0,i_N})? temp2[257:1] - {1'b0,i_N} : temp2[257:1]  ) : temp2[257:1]  ;
end
always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		mont_counter_r <= 0 ;
		m_r <= 0 ;
		finish_one_task <= 0 ;
		state_r <= 0 ;
	end
	else begin
		mont_counter_r <= (i_start)? 0 : mont_counter_w ;
		m_r <= (i_start || (state_r==1))? 0 : m_w ;
		finish_one_task <= (mont_counter_r==255)  ;
		state_r <= (i_start)? 0 : state_w ;
	end
end

endmodule

module MoP(
rst,
clk, 
curr_state,
Divisor_N,
Multipiler, 
Modulo_m,
MoP_Done
);

input          rst, clk;
input  [1 : 0] curr_state;
input  [255:0] Divisor_N;
input  [255:0] Multipiler;
output [255:0] Modulo_m;
output         MoP_Done;

parameter   IDLE = 2'd00; //HOLD ON
parameter	PREP = 2'd01; //HOLD ON
			
logic [257:0] mod_count_r, mod_count_w;
logic [8  :0] counter_r, counter_w;
logic [257:0] Temp_T_r, Temp_T_w;
logic [257:0] Divis_r, Divis_w;
logic save_w, save_r;

always@(posedge rst or posedge clk)begin
	if(rst)begin
		mod_count_r    <= 0;
		counter_r      <= 0;
		Temp_T_r       <= 0;
		Divis_r        <= 0;
		save_r         <= 0;
	end
	else begin
		mod_count_r    <= mod_count_w;
		counter_r      <= counter_w;
		Temp_T_r       <= Temp_T_w;
		Divis_r        <= Divis_w;
		save_r         <= save_w;
	end
end 

always_comb begin: counter_work
	save_w = save_r;
	counter_w = counter_r;
	if(curr_state != PREP)begin
		counter_w = 0;
		save_w = 0;
	end
	else begin
		counter_w = (counter_r == 256) ? 0 : counter_r + 1;
		save_w = (counter_r == 256);
	end
end

always_comb begin: Value_assignment
	mod_count_w  = mod_count_r;
	Temp_T_w     = Temp_T_r;
	Divis_w      = Divis_r;
	
	if(curr_state != PREP)begin
		mod_count_w  = 0;
		Temp_T_w     = Multipiler;
		Divis_w      = Divisor_N;
	end
	else begin
		if(counter_r == 256)begin
			mod_count_w = (Temp_T_r >= Divis_r) ? Temp_T_r - Divis_r : Temp_T_r;
		end
		Temp_T_w = ((Temp_T_r << 1) >= Divis_r) ? (Temp_T_r << 1) - Divis_r : (Temp_T_r << 1);
	end
end

assign Modulo_m = (mod_count_r[255:0]);
assign MoP_Done = save_r;

endmodule
