//**************************************
// File Name        : vga.sv
// Created Time     : 2025/06/11 16:30
// Last Revised Time: 2025/06/11 16:30
//**************************************
`timescale 1ns/10ps  
module Tracking_tb;
  // fileIO
  integer data_file;
  integer scan_file;
  `define NULL 0
  integer i;
  // clock rate is 25MHz, clock period is 40ns
  localparam CLK = 40;
  localparam HCLK = CLK/2;
  reg [7:0] str1, str2, str3;
  reg clk, rst_n;
  reg [23:0] color;
  reg pixelVAL;
  reg trackedVAL; 
  reg [ 9:0] pointH, pointV;
  wire o_trackedVAL;
  // generate the clock
	initial clk = 0;
	always #HCLK clk = ~clk;
  
  // connect the module
  Tracker u0(
    .i_rst_n(rst_n),
    .i_clk(clk),
    .i_RGB(color),
    .i_pixelVAL(pixelVAL),
    .o_pointH(pointH),
    .o_pointV(pointV),
    .o_valid(o_trackedVAL)
  );

  initial begin
    $fsdbDumpfile("tracking.fsdb");
    $fsdbDumpvars();
    $fsdbDumpMDA;
  end

  initial begin
    $display("==============");
    $display("Simulation Start");
    $display("==============");
    data_file = $fopen("./tb_verilog/640x480data.txt", "r");
    pixelVAL = 0;
    color = 0;
    rst_n = 1;
    #(2*CLK)
    rst_n = 0;
    #(CLK)
    rst_n = 1;
    #(CLK)

    while (data_file != `NULL) begin 
      @(posedge clk);  
      scan_file = $fscanf(data_file, "%d %d %d\n", str1, str2, str3);
      color = {str1, str2, str3};
      pixelVAL = 1;
      #(CLK);
      pixelVAL = 0;
      #(2*CLK);
      if (trackedVAL) begin
        $display(pointH, pointV);
        $display("==============");
        $display("   finished   ");
        $display("==============");
        $fclose(data_file);
        $finish;
      end
    end
    $fclose(data_file);
    $display("Data transmission is finished");
    
  end

  initial begin
    # (5e6*CLK)
    $display("==============");
    $display(" Not finished ");
    $display("==============");
    $finish;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      trackedVAL <= 0;
    end
    else begin
      trackedVAL <= o_trackedVAL;
    end
  end
endmodule