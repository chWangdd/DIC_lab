//**************************************
// File Name        : Top.sv
// Created Time     : 2025/05/15 20:00
// Last Revised Time: 2025/05/21 17:00
//**************************************

module Top (
  input i_clk,
  input i_clk_25M,
  input i_rst_n,

  input i_key_0,
  input i_key_1,
  input i_key_2,

  output [7:0] o_VGA_R,
  output [7:0] o_VGA_G,
  output [7:0] o_VGA_B,
  output o_V_sync,
  output o_H_sync,
  output o_VGA_BLANK_N,
  output o_request

);
  logic sending_r, sending_w;
  logic[23: 0] vgaStream_r, vgaStream_w;

  VGAController vga0(
    .i_clk(i_clk_25M),
    .i_rst_n(i_rst_n),
    .i_color(vgaStream_r),
    .o_VGA_B(o_VGA_B),
    .o_VGA_G(o_VGA_G),
    .o_VGA_R(o_VGA_R),
    .o_V_sync(o_V_sync),
    .o_H_sync(o_H_sync),
    .o_blank_n(o_VGA_BLANK_N),
    .o_request(o_request)
  );
  // for test the vga protocol
  always @(*) begin
    vgaStream_w = vgaStream_r;
    if (i_key_0) begin
      vgaStream_w = {8'd250, 8'b0, 8'b0};
    end else if (i_key_1) begin 
      vgaStream_w = {8'b0, 8'd250, 8'b0};
    end else if (i_key_2) begin
      vgaStream_w = {8'b0, 8'b0, 8'd250};
    end
  end

  // Sequantial Block
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      sending_r <= 0;
      vgaStream_r <= 0;
    end else begin
      sending_r <= sending_w;
      vgaStream_r <= vgaStream_w;
    end
  end
  
endmodule