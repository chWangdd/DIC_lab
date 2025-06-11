module recognition_top(
    i_clk,
    i_rst_n,
    i_valid,
    marker_x,
    marker_y,
    i_record, // key1
    i_recognize, // key2
    break_point,
    i_endall, // key3
    //input_timing
    core_mem_r_value,
    core_mem_w_value,
    core_mem_addr,
    core_mem_wr,
    core_mem_request,  
    core_wait 
);

input i_clk ;
input i_rst_n ;
input i_valid ;

input i_record ;
input i_recognize ;

input break_point ; // i_deny
input input_timing ;

input  core_mem_r_value [15:0] ;
output core_mem_w_value [15:0] ;
output core_mem_addr [19:0] ;
output core_mem_wr ;
output core_mem_request ;
input core_wait ;

parameter S_idle  = 3'd0  ;
parameter S_record  = 3'd1 ;
parameter S_resample = 3'd2 ;
parameter S_recognize = 3'd3 ; 
parameter S_runtest = 3'd4 ; 
parameter S_test_resample = 3'd5 ; 
parameter S_sim  = 3'd6 ; 


logic [4:0] state_r, state_w ;
logic [19:0]store_addr_r, store_addr_w ;

logic record_mode_r, record_mode_w ; 
logic recognize_mode_r, recognize_mode_w ;

logic stop_resample_wait0 ; // record mode, when you see memory value, it means we can stop resampling 
logic stop_test_resample ; //  test mode, when you see memory value, it means we can stop resampling 
logic stop_resample_wait2616 ;  //  when we do sim dot product, we need to load library feature vectors from A to Z

// A : 0~1023
// B : 1024~2047
// RT : 26*1024~27*1024-1

// feature vector A : 0~15
// feature vector B : 1024~1039
// feature vector RT: 26*1024~26*1024+15

logic [15:0]core_mem_w_value_r, core_mem_w_value_w ;
logic [15:0]core_mem_addr_r, core_mem_addr_w ;

assign core_mem_w_value = (state_r==S_record)? ;
assign core_mem_addr =  ;
assign core_mem_wr = ;
assign core_mem_request = ;

////// record mode and recognize mode
    always_comb begin
       // Default Values
       record_mode_w = 0 ;
       recognize_mode_w = 0 ;
       // FSM
       case(record_mode_r)
       0: begin 
        record_mode_w = (i_record)? 1 : 0 ;
        recognize_mode_w = (i_recognize)? 1 : 0 ;
       end
       1: begin 
        record_mode_w = (i_record)? 0 : 1 ;
        recognize_mode_w = (i_recognize)? 0 : 1 ;
       end
       endcase
    end
////// mem_addr control
    always_comb begin
       core_mem_addr_w = 0 ;

       case(state_r)
       S_record: begin 
        core_mem_addr_w  = ;
       end
       S_resample: begin 
        core_mem_addr_w  =  ;
       end
       S_test_resample: begin 
        core_mem_addr_w  =   ;
       end
       S_runtest: begin 
        core_mem_addr_w  =  ;
       end
       endcase
    end
////// state machine
    always_comb begin
       // Default Values
       state_w = S_idle ;
       // FSM
       case(state_r)
           S_idle          : state_w = (record_mode_r)? S_record : ( (recognize_mode_r)? S_runtest : S_idle ) ;
           S_record        : state_w = (record_mode_r)? S_record : S_resample ;
           S_resample      : state_w = (stop_resample_wait0)? S_idle : S_resample   ;

           S_runtest       : state_w = (break_point)  ? S_test_resample : S_runtest  ;
           S_test_resample : state_w = (stop_test_resample)?  S_lib_load : S_test_resample ;
           S_sim           : state_w = (stop_resample_wait2616)?  S_runtest : S_sim ;
           default : state_w = S_idle ;
       endcase
    end
//////  flip flop
    always_ff @(posedge i_clk or negedge i_rst_n) begin
       // reset
       if (!i_rst_n) begin
            record_mode_r < = 0 ;
            recognize_mode_r <= 0 ;
       end
       else begin
            record_mode_r < = record_mode_w ;
            recognize_mode_r <= recognize_mode_w ;
       end
    end

library_store ls1(
	input i_clk, 
	input i_rst_n,
	input [4:0]i_x,
	input [4:0]i_y,
	input i_deny, 
	input i_start, 
	input i_valid, 
	output [4:0] o_x,
	output [4:0] o_y, 
	output [14:0] o_addr
);

curve_total_length ctl1(
    input i_clk,
    input i_rst_n,
    input i_valid,
    input [11:0] i_index,
    input [22:0] i_total_length,
    input i_new_point_x[4:0],
    input i_new_point_y[4:0],
    output o_total_length[22:0],
    output o_valid
);

resample_point rep1(
    input i_clk,
    input i_rst_n,
    input i_valid,
    input [4:0]i_x,
    input [4:0]i_y,
    input [11:0] i_index,
    input [22:0] i_cum_length,
    output [9:0]  o_x ,
    output [9:0]  o_y  ,
    output [11:0] o_index ,
    output o_valid
);

similarity sim1(
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
SRAM_Controller sc1(

.i_clk(),
.i_rst(),
.inputtimming(), 
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
endmodule