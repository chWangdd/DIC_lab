module TrajAdder (
  input  i_clk,
  input  i_rst_n,
  input  [29:0] i_color,
  input  [ 9:0] i_h,
  input  [ 9:0] i_v,
  input  i_rendering,
  input  [ 9:0] i_pointH,
  input  [ 9:0] i_pointV,
  input  i_pointVAL,
  output [29:0] o_color
);
  
  localparam lineWidth = 1;
  `define frameWidth = 640;
  `define frameHeight = 480;
  // =========================================
  // Reg/wire declarations
  // =========================================
  reg [29:0] trajColor;
  reg [ 9:0] pointH;
  reg [ 9:0] pointV;
  // reg [`frameWidth-1: 0] trag[0: `frameHeight-1];
  wire isTrajectory;
  // =========================================
  // wire assignments
  // =========================================
  assign isTrajectory = (i_h >= pointH + lineWidth && i_h <= pointH + lineWidth && 
                         i_v >= pointV + lineWidth && i_v <= pointV + lineWidth);
  assign o_color = (!i_rendering) ? i_color:
                   (!isTrajectory)? i_color: trajColor;
  
  always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
      trajColor <= {10'd0, 8'd200, 12'd0};
      pointH <= {10{1'd1}};
      pointV <= {10{1'd1}};
    end
    else begin
      trajColor <= trajColor;
      pointH <= pointH;
      pointV <= pointV;
      if (i_pointVAL) begin
        pointH <= i_pointH;
        pointV <= i_pointV;
      end
    end
  end


endmodule