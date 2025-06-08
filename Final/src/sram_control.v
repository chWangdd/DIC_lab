module(
	input i_clk,
	input i_rst_n,
    output [15:0]core_mem_r_value,
    input  [15:0]core_mem_w_value,
    input [19:0]core_mem_addr,
    input core_mem_wr,
    input core_mem_valid,
	input core_mem_request,
	output core_wait,
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ, 
	output o_SRAM_WE_N,
	output o_SRAM_CE_N,
	output o_SRAM_OE_N,
	output o_SRAM_LB_N,
	output o_SRAM_UB_N
);

assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

endmodule