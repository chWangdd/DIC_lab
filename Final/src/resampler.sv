module curve_total_length (
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


assign o_valid = valid ;
assign o_total_length = L_r ;

logic old_point_x_r[4:0] ;
logic old_point_y_r[4:0] ;

logic [22:0] L_w, L_r ;

logic [4:0] delta_x ;
logic [4:0] delta_y ;
logic [10:0] delta  ;

logic valid ;


always_comb begin
    delta_x = (i_new_point_x > old_point_x_r)? i_new_point_x - old_point_x_r : old_point_x_r - i_new_point_x ;
    delta_y = (i_new_point_y > old_point_y_r)? i_new_point_y - old_point_y_r : old_point_y_r - i_new_point_y ;
    delta = delta_x * delta_x + delta_y * delta_y ;
    L_w = (i_valid)? L_r +  delta : L_r ;
end


always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        old_point_x_r <= 0 ;
        old_point_y_r <= 0 ;
        ready         <= 0 ;
        L_r <= 0 ;
        valid <= 0 ;
	end
	else begin
        old_point_x_r <= (i_valid)? i_new_point_x : old_point_x_r;
        old_point_y_r <= (i_valid)? i_new_point_y : old_point_y_r;
        ready         <= i_valid ;
        L_r           <= L_w ;
        valid         <= i_valid ;
	end
end

endmodule

module resample_point (
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

logic [4:0]  old_x_r ;
logic [4:0]  old_y_r ;

logic [22:0] cumL_w, cumL_r;
logic [22:0] L_w, L_r;

logic [5:0]  delta_x_w, delta_x_r ;
logic [5:0]  delta_y_w, delta_y_r ;
logic [12:0] delta_xsqr_w, delta_xsqr_r ;
logic [12:0] delta_ysqr_w, delta_ysqr_r ;

logic pipeline_1_r,pipeline_1_w ;
logic pipeline_2_r,pipeline_2_w ;
logic pipeline_3_r,pipeline_3_w ;
logic pipeline_4_r,pipeline_4_w ;
logic pipeline_5_r,pipeline_5_w ;

logic t2_r,t2_w ;
logic t3_r,t3_w ;
logic t4_r,t4_w ;
logic t5_r,t5_w ;
logic xmin1_1_r ;
logic xmin1_2_r ;


logic [9:0]o_x_r, o_x_w ;
logic [9:0]o_y_r, o_y_w ;
logic [11:0] o_index_w, o_index_r ;
logic o_valid_r,o_valid2_r,o_valid3_r,o_valid4_r ;

logic [20:0] average_segment  ;
logic [1:0]  interpolate_case ;
logic [22:0] curr_segment     ;

assign average_segment = i_cum_length[22:2] ;
assign curr_segment = cumL_r + delta ;
assign interpolate_case = (curr_segment>average_segment)? 1 : (curr_segment==average_segment)? 3 : 0 ;
assign o_index = o_index_r ;
assign o_valid = o_valid4_r ;
assign o_x = (average_segment)*(pipeline_4_r);
assign o_y = (average_segment)*(16-pipeline_4_r);

always_comb begin // cosine, sine記得負號
    delta_x_w = (i_x>old_x_r)? i_x - old_x_r : old_x_r - i_x ;
    delta_y_w = (i_y>old_y_r)? i_y - old_y_r : old_y_r - i_y ;
    delta_xsqr_w =  (delta_x_w)*(delta_x_w) ; // 64
    delta_ysqr_w =  (delta_y_w)*(delta_y_w) ; // 73
    delta = delta_xsqr_w + delta_ysqr_w ;
    o_index_w = (i_valid)? o_index_r + 1 : o_index_r  ;  
    pipeline_1_w = (delta_xsqr_r<<4) /  (delta_ysqr_r+delta_xsqr_r) ; // (64/73) = x1 ,target = (x1)^(1/2)
    t2_w = pipeline_1_r - 16 ;
    pipeline_2_w = 16 + ((t2_w)>>1)  ;
    t3_w = (xmin1_1_r) * (t2_r) ;
    pipeline_3_w = pipeline_2_r - ((t3_w)>>3) ;
    t4_w = (xmin1_2_r) * (t3_r) ;
    pipeline_4_w = 16 + ((t3_r)>>4)  ;
end

always_comb begin
    cumL_w = cumL_r ;
    case(interpolate_case)
    0 : cumL_w = (i_valid)? curr_segment : cumL_r ;
    2 : cumL_w = (i_valid)? curr_segment : cumL_r ;
    1 : cumL_w = (i_valid)? curr_segment - average_segment : cumL_r ;
    3 : cumL_w = (i_valid)? curr_segment - average_segment : cumL_r ;
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        old_x_r <= 0 ;
        old_y_r <= 0 ;
        cumL_r <= 0 ;
        o_valid_r <= 0 ;
        o_index_r <= 0 ;
        delta_x_r <= 0 ;
        delta_y_r <= 0 ;
        delta_xsqr_r <= 0 ;
        delta_ysqr_r <= 0 ;
        pipeline_1_r <= 0 ;
        pipeline_2_r <= 0 ;
        pipeline_3_r <= 0 ;
        pipeline_4_r <= 0 ;
	end
	else begin
        old_x_r <= (i_valid)? i_x : old_x_r ;
        old_y_r <= (i_valid)? i_y : old_y_r ;
        cumL_r <= cumL_w ; 
        o_valid_r <= (interpolate_case==0 || interpolate_case==3) ;
        o_index_r <= o_index_w ;
        delta_x_r <= delta_x_w ;
        delta_y_r <= delta_y_w ;
        delta_xsqr_r <= delta_xsqr_w ;
        delta_ysqr_r <= delta_ysqr_w ;
        xmin1_1_r <= t2_w ;
        xmin1_2_r <= xmin1_1_r ;
        pipeline_1_r <= pipeline_1_w ;
        o_valid2_r <=  o_valid_r ;
        pipeline_2_r <= pipeline_2_w ;
        o_valid3_r <=  o_valid2_r ;
        pipeline_3_r <= pipeline_3_w ;
        o_valid4_r <=  o_valid3_r ;
        pipeline_4_r <= pipeline_4_w ;
	end
end

endmodule

