module MoP(
rst,
clk, 
curr_state,
Divisor_N,
Multipiler, 
Modulo,
MoP_Done
);

input          rst, clk;
input  [1 : 0] curr_state;
input  [255:0] Divisor_N;
input  [255:0] Multipiler;
output [255:0] Modulo_m;
output         MoP_Done;

parameter   IDLE = ; //HOLD ON
			PREP = ; //HOLD ON
			
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

assign Module = (mod_count_r[255:0]);
assign MoP_Done = save_r;

endmodule