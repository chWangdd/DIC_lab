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

);

input i_clk ;
input i_rst_n ;
input i_valid ;

input marker_x ;
input marker_y ;
input i_endall ;

input i_record ;
input i_recognize ;

input break_point ; // i_deny


//input  core_mem_r_value [15:0] ;
//output core_mem_w_value [15:0] ;
//output core_mem_addr [19:0] ;
//output core_mem_wr ;
//output core_mem_request ;
//input core_wait ;

parameter S_idle  = 3'd0  ;
parameter S_record  = 3'd1 ;
parameter S_resample = 3'd2 ;
parameter S_recognize = 3'd3 ; 
parameter S_runtest = 3'd4 ; 
parameter S_test_resample = 3'd5 ; 
parameter S_sim  = 3'd6 ; 


logic [4:0] state_r, state_w ;
logic [19:0]store_addr_r, store_addr_w ;

logic [7:0] RT_x[0:15] ;
logic [7:0] RT_y[0:15] ;
logic [7:0] RT_x_sim ;
logic [7:0] RT_y_sim ;

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

logic [4:0]  libstr_ox, libstr_oy ;
logic [19:0] libstr_addr ;

logic mem_valid ;
logic sim_mem_valid ;

logic [15:0]core_mem_w_value_r, core_mem_w_value_w ;
logic [15:0]core_mem_addr_r, core_mem_addr_w ;

logic answer_valid;
logic [4:0] answer ;

logic [3:0] feature_vector_index ;

logic [19:0] curr_total_length ;
logic [19:0] final_total_length ;
logic curve_o_valid ;

logic [7:0] resample_feature_x ;
logic [7:0] resample_feature_y ;
logic [3:0] resample_feature_index ;
logic resample_feature_valid ;

logic refresh_curveL ;
logic [9:0] mem_counter;
logic [15:0]sram_dq;


assign core_mem_w_value = (state_r==S_record)? {3'd0,marker_x,3'd0,marker_y} : {resample_feature_x,resample_feature_y} ;
assign core_mem_addr = core_mem_addr_r ;
assign core_mem_wr = (i_valid) & (state_r==S_runtest || state_r==S_record) ;
assign core_mem_request = (state_r==S_record && i_valid) || (state_r==S_runtest && i_valid) || (state_r==S_resample && (resample_feature_valid|mem_valid)) || (state_r==S_test_resample && (resample_feature_valid|mem_valid)) ;

assign sim_mem_valid  = (mem_valid) & (state_r==S_sim) ;
assign refresh_curveL = (state_r==S_test_resample) & (state_r==S_resample) ;


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
       S_idle: begin 
        core_mem_addr_w  = 0 ;
       end
       S_record: begin 
         core_mem_addr_w  = (i_valid)? core_mem_addr_r + 1 :  core_mem_addr_r ;
       end
       S_resample: begin 
        core_mem_addr_w  =  (resample_feature_valid)? resample_feature_index :  ((mem_valid)? core_mem_addr_r+1 : core_mem_addr_r) ; 
       end
       S_runtest: begin 
        core_mem_addr_w  =  (break_point)? 0 : ( (i_valid)? core_mem_addr_r + 1 : core_mem_addr_r ) ;
       end
       S_test_resample : begin 
        core_mem_addr_w  =  (resample_feature_valid)? resample_feature_index :  ((mem_valid)? core_mem_addr_r+1 : core_mem_addr_r) ; 
       end
       S_sim: begin 
        core_mem_addr_w  =  {5'd0, mem_counter[8:4], 6'd0, mem_counter[3:0]} ; // Av1-Av16,Bv1-Bv16
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
           S_test_resample : state_w = (stop_test_resample)?  S_runtest : S_test_resample ;
           S_sim           : state_w = (stop_resample_wait2616)?  S_runtest : S_sim ;
           default : state_w = S_idle ;
       endcase
    end
//////  flip flop
    always_ff @(posedge i_clk or negedge i_rst_n) begin
       // reset
       if (!i_rst_n) begin
            record_mode_r <= 0 ;
            recognize_mode_r <= 0 ;
            mem_counter <= 0 ;
            core_mem_addr_r <= 0 ;
       end
       else begin
            record_mode_r <= record_mode_w ;
            recognize_mode_r <= recognize_mode_w ;
            mem_counter <= (state_r==S_sim || state_r==S_resample || state_r==S_test_resample)? ((mem_valid)? mem_counter+1 : mem_counter ) : (0) ;
            core_mem_addr_r <= core_mem_addr_w ;
       end
    end
// finish
library_store ls1(
	.i_clk(i_clk), 
	.i_rst_n(i_rst_n),
	.i_x(marker_x),
	.i_y(marker_y),
	.i_start(i_record), // first high to start, second high to end
	.i_valid(i_valid), 
	.o_x(libstr_ox),
	.o_y(libstr_oy), 
	.o_addr(libstr_addr)
);

curve_total_length ctl1(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_valid(i_valid),
    //.i_index(),
    .i_refresh(refresh_curveL), // refresh after normalization
    .i_total_length(curr_total_length),
    .i_new_point_x(sram_dq[4:0]), 
    .i_new_point_y(sram_dq[12:8]), 
    .o_total_length(final_total_length) , 
    .o_valid(curve_o_valid) 
);

resample_point rep1(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_valid(i_valid),
    .i_x(sram_dq[4:0]), // mem
    .i_y(sram_dq[12:8]), // mem
    //.i_index(),
    .i_cum_length(final_total_length), 
    .o_x(resample_feature_x), 
    .o_y(resample_feature_y),
    .o_index(resample_feature_index), 
    .o_valid(resample_feature_valid)  
);

// finish
similarity sim1(
	.i_clk(i_clk), 
	.i_rst_n(i_rst_n),
	.i_valid(sim_mem_valid),   
	.i_index(feature_vector_index), 
	.vector_x(RT_x_sim),
	.vector_y(RT_y_sim),
	.lib_x(sram_dq[15:8]), // mem_related, related to
	.lib_y(sram_dq[7:0]), // mem_related
	.o_valid(answer_valid), 
	.o_index(answer)
);

// A : 0~1023
// B : 1024~2047
// RT : 26*1024~27*1024-1

// feature vector A : 0~15
// feature vector B : 1024~1039
// feature vector RT: 26*1024~26*1024+15

// [5+3:0]counter_lower , 16 =  10000 , 
// sram_addr = {5'b0, counter_lower[8:4], 6'b0, counter_lower[3:0]}


SRAM_Controller sc1(

.i_clk(i_clk),
.i_rst_n(i_rst_n),
.mem_valid(mem_valid), // mem_valid, ok
// Input assignment
.core_mem_w_value(core_mem_w_value), 
.core_mem_addr(core_mem_addr_r),
.core_mem_wr(),
.core_mem_request(),
	
// Output
.core_mem_r_value(core_mem_r_value),
.core_wait(),
.o_SRAM_ADDR(),
.o_SRAM_WE_N(),
.o_SRAM_CE_N(),
.o_SRAM_OE_N(),
.o_SRAM_LB_N(),
.o_SRAM_UB_N(),
	
// Inout
.io_SRAM_DQ(sram_dq)
);

endmodule