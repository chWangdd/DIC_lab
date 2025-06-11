module recognition_top(
    i_clk,
    i_rst_n,
    i_valid,
    marker_x,
    marker_y,
    i_record,
    i_recognize,
    break_point,
    input_timing
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
parameter S_resapmle = 3'd2 ;
parameter S_recognize = 3'd3 ; 
parameter S_test_resample = 3'd4 ; 
parameter S_runtest = 3'd5 ; 

logic record_mode_r, record_mode_w ; 
logic recognize_mode_r, recognize_mode_w ;
logic [4:0] state_r, state_w ;
logic [19:0]store_addr_r, store_addr_w ;

logic [15:0]core_mem_w_value_r, core_mem_w_value_w ;
logic [15:0]core_mem_addr_r, core_mem_addr_w ;

assign core_mem_w_value = (state_r==S_record)? ;
assign core_mem_addr =  ;
assign core_mem_wr = ;
assign core_mem_request

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
        core_mem_addr_w  =  (i_recognize)? 1 : 0 ;
       end
       S_resample: begin 
        core_mem_addr_w  =  (i_recognize)? 1 : 0 ;
       end
       S_test_resample: begin 
        core_mem_addr_w  =  (i_recognize)? 1 : 0 ;
       end
       S_runtest: begin 
        core_mem_addr_w  =  (i_recognize)? 1 : 0 ;
       end
       endcase
    end
////// state machine
    always_comb begin
       // Default Values
       state_w = S_idle ;
       // FSM
       case(state_r)
           S_idle          : state_w = (record_mode_r)? S_record : ( (recognize_mode_r)? S_stop_sample_input : S_idle ) ;
           S_record        : state_w = (record_mode_r)? S_record : S_idle ;
           S_resample      : state_w = (record_mode_r)? ((breakpoint)?S_stop_sample_input:S_sample_input) : S_idle;
           S_test_resample : state_w = (record_mode_w)? ((breakpoint)?S_stop_sample_input:S_sample_input) : S_idle ;
           S_runtest       : state_w = (record_mode_w)? ((breakpoint)?S_stop_sample_input:S_sample_input) : S_idle ;
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


endmodule