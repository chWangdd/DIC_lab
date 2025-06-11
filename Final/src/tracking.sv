module Tracker (
  input i_rst_n,
  input i_clk,
  input [23:0] i_RGB,
  input i_pixelVAL,
  
  output [ 4:0] o_pointH,
  output [ 4:0] o_pointV,
  // output o_isTracking,
  output o_valid
);
  // `include "vga_param.sv"
  `include "tracking_param.sv"
  localparam totalH = 640;
  localparam totalH_half = 320;
  localparam totalV = 480;
  localparam totalV_half = 240;
  localparam S_RESET = 0;
  localparam S_CAL0  = 1; // preious Point is (0,0)  
  localparam S_CAL1  = 2; // general case
  localparam S_UPDATE= 3; // there is a tracking point be generated

  // =========================================
  // Reg/Wire Declaration
  // =========================================
  reg [ 1:0] state_ff, state_comb;
  reg [ 1:0] pixelGrade_ff, pixelGrade_comb;
  reg [ 4:0] maxPointH_ff, maxPointH_comb, maxPointV_ff, maxPointV_comb; // candidate point
  reg [14:0] maxPointValue_ff, maxPointValue_comb;                        // value of candidate point
  reg [14:0] prePointH_ff, prePointH_comb, prePointV_ff, prePointV_comb;  // previous tracked point
  reg [ 9:0] Hcnt_ff, Hcnt_comb;
  reg [ 9:0] Vcnt_ff, Vcnt_comb;
  // detection range
  reg [ 9:0] startH_ff, startH_comb, startV_ff, startV_comb;
  reg [ 9:0] endH_ff, endH_comb, endV_ff, endV_comb;
  // control signal for static frames
  reg [`rangeH-1: 0] SF_reset1_ff, SF_reset1_comb;
  reg [`rangeH-1: 0] SF_reset2_ff, SF_reset2_comb;
  reg [ 7:0] SF_startOffsetH1_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetV1_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetH1_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetV1_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetH2_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetV2_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetH2_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 7:0] SF_startOffsetV2_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  // reg [ 3:0] frame [0:`subFrameH][0:`subFrameV];
  // reg [ 3:0] frame_nxt [0:`subFrameH][0:`subFrameV];
  reg pointGenerated_ff, pointGenerated_comb;

  wire i_clk;
  wire [ 7:0] iR, iG, iB;
  wire [ 7:0] iB_G, iB_R;
  wire [`rangeH-1: 0] SF_valid1;
  wire [`rangeH-1: 0] SF_valid2;
  wire [ 7:0] SF_sum1 [0:`rangeH-1];
  wire [ 7:0] SF_sum2 [0:`rangeH-1];

  wire [ 9:0] SF_startH1 [0: `rangeH-1];
  wire [ 9:0] SF_startV1 [0: `rangeH-1];
  wire [ 9:0] SF_startH2 [0: `rangeH-1];
  wire [ 9:0] SF_startV2 [0: `rangeH-1];
  // there is a tracking point generated
  wire [ 9:0] startHInit [0: `rangeH-1];
  integer i;
  // =========================================
  // Wires assignment
  // =========================================
  assign iR = i_RGB[23:16];
  assign iG = i_RGB[15: 8];
  assign iB = i_RGB[ 7: 0];
  assign iB_R = (iB > iR) ? iB -iR: 0;
  assign iB_G = (iB > iG) ? iB -iG: 0;
  assign o_valid = pointGenerated_ff; 

  genvar n;
  generate
    for (n = 0; n < `rangeH ; n = n + 1) begin
      assign SF_startH1[n] = startH_ff + SF_startOffsetH1_ff[n];
      assign SF_startV1[n] = startV_ff + SF_startOffsetV1_ff[n];
      assign SF_startH2[n] = startH_ff + SF_startOffsetH2_ff[n];
      assign SF_startV2[n] = startV_ff + SF_startOffsetV2_ff[n];

    end
  endgenerate
  // =========================================
  // Module Declarations
  // =========================================

  // first row of staticFrames
  genvar n1;
  generate
    for(n1 = 0; n1 < `rangeH; n1 = n1 + 1) begin : subFrame_chain1
      staticFrame SFa (
          .i_clk(i_clk),
          .i_rst_n(~SF_reset1_ff[n1]),
          .i_h(Hcnt_ff),
          .i_v(Vcnt_ff),
          .istart_h(SF_startH1[n1]),
          .istart_v(SF_startV1[n1]),
          .idata(pixelGrade_ff),
          .o_valid(SF_valid1[n1]),
          .o_sum(SF_sum1[n1])
      );
    end
  endgenerate

  // second row of staticFrames
  genvar n2;
  generate
    for(n2 = 0; n2 < `rangeH; n2 = n2 + 1) begin : subFrame_chain2
      staticFrame SFb (
          .i_clk(i_clk),
          .i_rst_n(~SF_reset1_ff[n2]),
          .i_h(Hcnt_ff),
          .i_v(Vcnt_ff),
          .istart_h(SF_startH2[n2]),
          .istart_v(SF_startV2[n2]),
          .idata(pixelGrade_ff),
          .o_valid(SF_valid2[n2]),
          .o_sum(SF_sum2[n2])
      );
    end
  endgenerate
  // =========================================
  // Combinational Block
  // =========================================
  always_comb begin : pixelGrade
    if (iB_R >= iB_G)
      pixelGrade_comb = iB_G[`gradeFactor:`gradeFactor-1];
    else if (iB_G > iB_R)
      pixelGrade_comb = iB_R[`gradeFactor:`gradeFactor-1];
    else
      pixelGrade_comb = pixelGrade_ff;
  end

  always_comb begin : counter
    Hcnt_comb = Hcnt_ff;
    Vcnt_comb = Vcnt_ff;
    if (i_pixelVAL) begin
      if (Hcnt_ff < totalH) begin
        Hcnt_comb = Hcnt_ff + 1;
      end
      else begin
        Hcnt_comb = 1;
        if (Vcnt_ff < totalV)
          Vcnt_comb = Vcnt_ff + 1;
        else
          Vcnt_comb = 1;
      end
    end
  end

  always_comb begin : state
  state_comb = state_ff;
    case (state_ff)
      S_RESET: begin
        state_comb = S_CAL1;  
      end
      S_CAL1: begin
        if((SF_startOffsetV1_ff[`rangeH-1] >= startV_ff + `possibleV) || (SF_startOffsetV2_ff[`rangeH-1] >= startV_ff + `possibleV)) //after a frame
          state_comb = S_UPDATE;
      end
      S_UPDATE:
        state_comb = S_CAL1; 
      default: 
        state_comb = state_ff;
    endcase
  end

  always_comb begin : maxPoint
    prePointH_comb = prePointH_ff;
    prePointV_comb = prePointV_ff;
    maxPointH_comb = maxPointH_ff;
    maxPointV_comb = maxPointV_ff;
    maxPointValue_comb = maxPointValue_ff;
    pointGenerated_comb = pointGenerated_ff;
    SF_reset1_comb = SF_reset1_ff;
    SF_reset2_comb = SF_reset2_ff;
    startH_comb = startH_ff;
    startV_comb = startV_ff;
    for (i = 0; i < `rangeH; i = i + 1) begin
      SF_startOffsetH1_comb[i] = SF_startOffsetH1_ff[i];
      SF_startOffsetV1_comb[i] = SF_startOffsetV1_ff[i];        
      SF_startOffsetH2_comb[i] = SF_startOffsetH2_ff[i];
      SF_startOffsetV2_comb[i] = SF_startOffsetV2_ff[i];        
    end

    case (state_ff)
      S_RESET: begin
        prePointH_comb = {0, totalH[8:0]};
        prePointV_comb = {0, totalV[8:0]};
      end
      S_CAL1: begin
        if (SF_valid1[0] && SF_startOffsetV1_ff[0] < startV_ff + `possibleV) begin // update the max point
          if (maxPointValue_ff < SF_sum1[0]) begin
            maxPointH_comb = SF_startH1[0];
            maxPointV_comb = SF_startV1[0];
            maxPointValue_comb = SF_sum1[0];
            SF_startOffsetH1_comb[0] = SF_startOffsetH1_ff[0];
            SF_startOffsetV1_comb[0] = SF_startOffsetV1_ff[0] + `subFrameV;
          end
          SF_reset1_comb[0] = 1;
        end   
        else if (SF_valid1[1] && SF_startOffsetV1_ff[1] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum1[1]) begin
            maxPointH_comb = SF_startH1[1];
            maxPointV_comb = SF_startV1[1];
            maxPointValue_comb = SF_sum1[1];
            SF_startOffsetH1_comb[1] = SF_startOffsetH1_ff[1];
            SF_startOffsetV1_comb[1] = SF_startOffsetV1_ff[1] + `subFrameV;
          end
          SF_reset1_comb[1] = 1;
        end   
        else if (SF_valid1[2] && SF_startOffsetV1_ff[2] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum1[2]) begin
            maxPointH_comb = SF_startH1[2];
            maxPointV_comb = SF_startV1[2];
            maxPointValue_comb = SF_sum1[2];
            SF_startOffsetH1_comb[2] = SF_startOffsetH1_ff[2];
            SF_startOffsetV1_comb[2] = SF_startOffsetV1_ff[2] + `subFrameV;
          end
          SF_reset1_comb[2] = 1;
        end
        else if (SF_valid1[3] && SF_startOffsetV1_ff[3] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum1[3]) begin
            maxPointH_comb = SF_startH1[3];
            maxPointV_comb = SF_startV1[3];
            maxPointValue_comb = SF_sum1[3];
            SF_startOffsetH1_comb[3] = SF_startOffsetH1_ff[3];
            SF_startOffsetV1_comb[3] = SF_startOffsetV1_ff[3] + `subFrameV;
          end
          SF_reset1_comb[3] = 1;
        end   
        else if (SF_valid1[4] && SF_startOffsetV1_ff[4] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum1[4]) begin
            maxPointH_comb = SF_startH1[4];
            maxPointV_comb = SF_startV1[4];
            maxPointValue_comb = SF_sum1[4];
            SF_startOffsetH1_comb[4] = SF_startOffsetH1_ff[4];
            SF_startOffsetV1_comb[4] = SF_startOffsetV1_ff[4] + `subFrameV;
          end
          SF_reset1_comb[4] = 1;
        end   
        else if (SF_valid1[5] && SF_startOffsetV1_ff[5] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum1[5]) begin
            maxPointH_comb = SF_startH1[5];
            maxPointV_comb = SF_startV1[5];
            maxPointValue_comb = SF_sum1[5];
            SF_startOffsetH1_comb[5] = SF_startOffsetH1_ff[5];
            SF_startOffsetV1_comb[5] = SF_startOffsetV1_ff[5] + `subFrameV;
          end
          SF_reset1_comb[5] = 1;
        end   
        else if (SF_valid1[6] && SF_startOffsetV1_ff[6] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum1[6]) begin
            maxPointH_comb = SF_startH1[6];
            maxPointV_comb = SF_startV1[6];
            maxPointValue_comb = SF_sum1[6];
            SF_startOffsetH1_comb[6] = SF_startOffsetH1_ff[6];
            SF_startOffsetV1_comb[6] = SF_startOffsetV1_ff[6] + `subFrameV;
          end
          SF_reset1_comb[6] = 1;
        end
        else if (SF_valid2[0] && SF_startOffsetV2_ff[0] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[0]) begin
            maxPointH_comb = SF_startH2[0];
            maxPointV_comb = SF_startV2[0];
            maxPointValue_comb = SF_sum2[0];
            SF_startOffsetH2_comb[0] = SF_startOffsetH2_ff[0];
            SF_startOffsetV2_comb[0] = SF_startOffsetV2_ff[0] + `subFrameV;
          end
          SF_reset2_comb[0] = 1;
        end   
        else if (SF_valid2[1] && SF_startOffsetV2_ff[1] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[1]) begin
            maxPointH_comb = SF_startH2[1];
            maxPointV_comb = SF_startV2[1];
            maxPointValue_comb = SF_sum2[1];
            SF_startOffsetH2_comb[1] = SF_startOffsetH2_ff[1];
            SF_startOffsetV2_comb[1] = SF_startOffsetV2_ff[1] + `subFrameV;
          end
          SF_reset2_comb[1] = 1;
        end   
        else if (SF_valid2[2] && SF_startOffsetV2_ff[2] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[2]) begin
            maxPointH_comb = SF_startH2[2];
            maxPointV_comb = SF_startV2[2];
            maxPointValue_comb = SF_sum2[2];
            SF_startOffsetH2_comb[2] = SF_startOffsetH2_ff[2];
            SF_startOffsetV2_comb[2] = SF_startOffsetV2_ff[2] + `subFrameV;
          end
          SF_reset2_comb[2] = 1;
        end   
        else if (SF_valid2[3] && SF_startOffsetV2_ff[3] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[3]) begin
            maxPointH_comb = SF_startH2[3];
            maxPointV_comb = SF_startV2[3];
            maxPointValue_comb = SF_sum2[3];
            SF_startOffsetH2_comb[3] = SF_startOffsetH2_ff[3];
            SF_startOffsetV2_comb[3] = SF_startOffsetV2_ff[3] + `subFrameV;
          end
          SF_reset2_comb[3] = 1;
        end   
        else if (SF_valid2[4] && SF_startOffsetV2_ff[4] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[4]) begin
            maxPointH_comb = SF_startH2[4];
            maxPointV_comb = SF_startV2[4];
            maxPointValue_comb = SF_sum2[4];
            SF_startOffsetH2_comb[4] = SF_startOffsetH2_ff[4];
            SF_startOffsetV2_comb[4] = SF_startOffsetV2_ff[4] + `subFrameV;
          end
          SF_reset2_comb[4] = 1;
        end   
        else if (SF_valid2[5] && SF_startOffsetV2_ff[5] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[5]) begin
            maxPointH_comb = SF_startH2[5];
            maxPointV_comb = SF_startV2[5];
            maxPointValue_comb = SF_sum2[5];
            SF_startOffsetH2_comb[5] = SF_startOffsetH2_ff[5];
            SF_startOffsetV2_comb[5] = SF_startOffsetV2_ff[5] + `subFrameV;
          end
          SF_reset2_comb[5] = 1;
        end   
        else if (SF_valid2[6] && SF_startOffsetV2_ff[6] < startV_ff + `possibleV) begin
          if (maxPointValue_ff < SF_sum2[6]) begin
            maxPointH_comb = SF_startH2[6];
            maxPointV_comb = SF_startV2[6];
            maxPointValue_comb = SF_sum2[6];
            SF_startOffsetH2_comb[6] = SF_startOffsetH2_ff[6];
            SF_startOffsetV2_comb[6] = SF_startOffsetV2_ff[6] + `subFrameV;
          end
          SF_reset2_comb[6] = 1;
        end
        SF_reset1_comb = 0;
        SF_reset2_comb = 0;
        pointGenerated_comb = 0;
      end
      S_UPDATE: begin // update the previous point and the next detecting range
        maxPointValue_comb = 0;
        prePointH_comb = maxPointH_ff;
        prePointV_comb = maxPointV_ff;
        pointGenerated_comb = 1;
        startH_comb = maxPointH_ff - `subFrameH * 3;
        startV_comb = maxPointV_ff - `subFrameV * 3;
        for (i = 0; i < `rangeH; i = i + 1) begin
          SF_startOffsetH1_comb[i] = `overlapH * i; // notice:
          SF_startOffsetV1_comb[i] = 0;        
          SF_startOffsetH2_comb[i] = `overlapH * i; // notice:
          SF_startOffsetV2_comb[i] = `overlapV;        
        end      
      end
      default: begin
        maxPointH_comb = maxPointH_ff;
        maxPointV_comb = maxPointV_ff;
        maxPointValue_comb = maxPointValue_ff;
        prePointH_comb = prePointH_ff;
        prePointV_comb = prePointV_ff;  
        pointGenerated_comb = pointGenerated_ff;
        for (i = 0; i < `rangeH; i = i + 1) begin
          SF_startOffsetH1_comb[i] = SF_startOffsetH1_ff[i];
          SF_startOffsetV1_comb[i] = SF_startOffsetV1_ff[i];        
          SF_startOffsetH2_comb[i] = SF_startOffsetH2_ff[i];
          SF_startOffsetV2_comb[i] = SF_startOffsetV2_ff[i];        
        end
      end      
    endcase
           
  end

  // =========================================
  // Sequential block
  // =========================================
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      state_ff         <= S_RESET;
      pixelGrade_ff    <= 0;
      prePointH_ff     <= {0, totalH[8:0]};
      prePointV_ff     <= {0, totalV[8:0]};
      maxPointH_ff     <= 0;
      maxPointV_ff     <= 0;
      maxPointValue_ff <= 0;
      Hcnt_ff          <= 1;
      Vcnt_ff          <= 1;
      SF_reset1_ff     <= 0;
      SF_reset2_ff     <= 0;
      startH_ff        <= {0, totalH[8:0]} - `subFrameH * 3;
      startV_ff        <= {0, totalV[8:0]} - `subFrameV * 3;
      for (i = 0; i < `rangeH; i = i + 1) begin
        SF_startOffsetH1_ff[i] <= 0;
        SF_startOffsetV1_ff[i] <= 0;
        SF_startOffsetH2_ff[i] <= 0;
        SF_startOffsetV2_ff[i] <= 0;
      end
    end
    else begin
      state_ff         <= state_comb;
      pixelGrade_ff    <= pixelGrade_comb;
      prePointH_ff     <= prePointH_comb;
      prePointV_ff     <= prePointV_comb;
      maxPointH_ff     <= maxPointH_comb;
      maxPointV_ff     <= maxPointV_comb;
      maxPointValue_ff <= maxPointValue_comb;
      Hcnt_ff          <= Hcnt_comb;
      Vcnt_ff          <= Vcnt_comb;
      SF_reset1_ff     <= SF_reset1_comb;
      SF_reset2_ff     <= SF_reset2_comb;
      startH_ff        <= startH_comb;
      startV_ff        <= startV_comb;
      for (i = 0; i < `rangeH; i = i + 1) begin
        SF_startOffsetH1_ff[i] <= SF_startOffsetH1_comb[i];
        SF_startOffsetV1_ff[i] <= SF_startOffsetV1_comb[i];        
        SF_startOffsetH2_ff[i] <= SF_startOffsetH2_comb[i];
        SF_startOffsetV2_ff[i] <= SF_startOffsetV2_comb[i];        
      end
    end
  end
endmodule

module staticFrame (
  input i_clk,
  input i_rst_n,
  input [ 9:0] i_h,
  input [ 9:0] i_v,
  input [ 9:0] istart_h,
  input [ 9:0] istart_v,
  input [ 1:0] idata,
  output o_valid,
  output [7:0] o_sum
);
  reg [14:0] acc_ff, acc_comb;
  reg valid_ff, valid_comb;
  
  assign o_sum = acc_ff[ 11:4];  // 要除多少??
  assign o_valid = valid_ff;
  
  always_comb begin
    acc_comb = acc_ff;
    valid_comb = valid_ff;
    if ((
          i_h >= istart_h && 
          i_h < istart_h + `subFrameH
        ) && (
          i_v >= istart_v && 
          i_v < istart_v + `subFrameV
        ))
      acc_comb = acc_ff + idata;

    // after accumulating data in the range of a frame, set "valid" HIGH
    if ((i_h >= istart_h + `subFrameH) && (i_v >= istart_v + `subFrameV - 1))
      valid_comb = 1;
  end

  always_ff @(posedge i_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      acc_ff <= 0;
      valid_ff <= 0;
    end
    else begin
      acc_ff <= acc_comb;
      valid_ff <= valid_comb;
    end
endmodule