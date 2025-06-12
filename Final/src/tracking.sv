module Tracker (
  input i_rst_n,
  input i_clk,
  input [23:0] i_RGB,
  input i_pixelVAL,
  // control signal
  input i_start,
  input i_hold,
  // output signal
  output [ 4:0] o_pointH,
  output [ 4:0] o_pointV,
  output o_isTracking,
  output o_valid
);
  // `include "vga_param.sv"
  `include "tracking_param.sv"
  localparam totalH = 640;
  localparam totalH_half = 320;
  localparam totalV = 480;
  localparam totalV_half = 240;
  localparam S_IDLE = 0;
  localparam S_CAL0  = 1; // preious Point is (0,0)  
  localparam S_CAL1  = 2; // general case
  localparam S_UPDATE= 3; // there is a tracking point be generated
  
  // =========================================
  // Reg/Wire Declaration
  // =========================================
  reg [ 1:0] state_ff, state_comb;
  reg [ 1:0] pixelGrade_ff;
  reg pixelGradeVAL_ff;
  reg updateTriggered_ff, updateTriggered_comb;
  reg [14:0] maxPointH_ff, maxPointH_comb, maxPointV_ff, maxPointV_comb; // candidate point
  reg [14:0] maxPointValue_ff, maxPointValue_comb;                        // value of candidate point
  reg [14:0] prePointH_ff, prePointH_comb, prePointV_ff, prePointV_comb;  // previous tracked point
  reg [ 9:0] Hcnt_ff;
  reg [ 9:0] Vcnt_ff;
  reg pixelVAL;
  reg hold;

  // detection range
  reg [ 9:0] startH_ff, startH_comb, startV_ff, startV_comb;
  reg [ 9:0] endH_ff, endH_comb, endV_ff, endV_comb;
  // control signal for static frames
  reg [`rangeH-1: 0] SF_reset1_ff, SF_reset1_comb;
  reg [`rangeH-1: 0] SF_reset2_ff, SF_reset2_comb;
  reg [ 8:0] SF_startOffsetH1_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetV1_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetH1_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetV1_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetH2_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetV2_ff [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetH2_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg [ 8:0] SF_startOffsetV2_comb [0: `rangeH-1];    // notice: it will overflow when the range is bigger (current is 32*7=224)
  reg pointGenerated_ff, pointGenerated_comb;
  reg isTracking;

  wire clk;
  wire [ 7:0] iR, iG, iB;
  wire [ 7:0] iB_G, iB_R;
  wire [ 7:0] iR_G, iR_B;
  wire [`rangeH-1: 0] SF_valid1;
  wire [`rangeH-1: 0] SF_valid2;
  wire [ 7:0] SF_sum1 [0:`rangeH-1];
  wire [ 7:0] SF_sum2 [0:`rangeH-1];
  wire [`rangeH-1: 0] findRed1;
  wire [`rangeH-1: 0] findRed2;

  wire [ 9:0] SF_startH1 [0: `rangeH-1];
  wire [ 9:0] SF_startV1 [0: `rangeH-1];
  wire [ 9:0] SF_startH2 [0: `rangeH-1];
  wire [ 9:0] SF_startV2 [0: `rangeH-1];
  // there is a tracking point generated
  integer i, j;
  // =========================================
  // Wires assignment
  // =========================================
  assign clk = i_clk;
  assign iR = i_RGB[23:16];
  assign iG = i_RGB[15: 8];
  assign iB = i_RGB[ 7: 0];
  assign iB_R = (iB > iR) ? iB - iR: 0;
  assign iB_G = (iB > iG) ? iB - iG: 0;
  assign iR_B = (iR > iB) ? iR - iB: 0;
  assign iR_G = (iR > iG) ? iR - iG: 0;
  assign o_valid = pointGenerated_ff; 
  assign o_isTracking = isTracking;
  assign o_pointH = maxPointH_ff[9:5];
  assign o_pointV = maxPointV_ff[9:5];
  genvar n;
  generate
    for (n = 0; n < `rangeH ; n = n + 1) begin : letgo
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
          .i_clk(clk),
          .i_rst_n(~SF_reset1_ff[n1]),
          .i_h(Hcnt_ff),
          .i_v(Vcnt_ff),
          .istart_h(SF_startH1[n1]),
          .istart_v(SF_startV1[n1]),
          .idata(pixelGrade_ff),
          .i_dataVAL(pixelGradeVAL_ff),
          .o_valid(SF_valid1[n1]),
          .o_sum(SF_sum1[n1]),
          .o_findRed(findRed1[n1])
      );
    end
  endgenerate

  // second row of staticFrames
  genvar n2;
  generate
    for(n2 = 0; n2 < `rangeH; n2 = n2 + 1) begin : subFrame_chain2
      staticFrame SFb (
          .i_clk(clk),
          .i_rst_n(~SF_reset2_ff[n2]),
          .i_h(Hcnt_ff),
          .i_v(Vcnt_ff),
          .istart_h(SF_startH2[n2]),
          .istart_v(SF_startV2[n2]),
          .idata(pixelGrade_ff),
          .i_dataVAL(pixelGradeVAL_ff),
          .o_valid(SF_valid2[n2]),
          .o_sum(SF_sum2[n2]),
          .o_findRed(findRed2[n2])
      );
    end
  endgenerate
  // =========================================
  // Combinational Block
  // =========================================

  always_comb begin : state
    state_comb = state_ff;
    pointGenerated_comb = pointGenerated_ff;
    updateTriggered_comb = updateTriggered_ff;
    case (state_ff)
      S_IDLE: begin
        if (i_start)
          state_comb = S_CAL1;
        pointGenerated_comb = 0;  
      end
      S_CAL0:
        state_comb = S_IDLE;
      S_CAL1: begin
        if (hold)
          state_comb = S_IDLE;
        else if((!updateTriggered_ff && (SF_startV1[`rangeH-1] > (startV_ff + `possibleV)) || (SF_startV2[`rangeH-1] > startV_ff + `possibleV) ||
                 SF_startV1[`rangeH-1] > totalV || SF_startV2[`rangeH-1] > totalV)) begin //after a frame
          state_comb = S_UPDATE;
          pointGenerated_comb = 1;
          updateTriggered_comb = 1;
        end
        else begin 
          state_comb = state_ff;
          pointGenerated_comb = pointGenerated_ff;
        end
      end
      S_UPDATE: begin
        if (hold) begin
          state_comb = S_IDLE;
        end
        else if ((Vcnt_ff == totalV) && (Hcnt_ff == totalH)) begin
          state_comb = S_CAL1;
          pointGenerated_comb = 0;
          updateTriggered_comb = 0;
        end
      end
      default: begin
        state_comb = state_ff;
        pointGenerated_comb = pointGenerated_ff;
        updateTriggered_comb = updateTriggered_ff;
      end
    endcase
  end

  always_comb begin : maxPoint
    prePointH_comb = prePointH_ff;
    prePointV_comb = prePointV_ff;
    maxPointH_comb = maxPointH_ff;
    maxPointV_comb = maxPointV_ff;
    maxPointValue_comb = maxPointValue_ff;
    SF_reset1_comb = SF_reset1_ff;
    SF_reset2_comb = SF_reset2_ff;
    startH_comb = startH_ff;
    startV_comb = startV_ff;
    for (j = 0; j < `rangeH; j = j + 1) begin
      SF_startOffsetH1_comb[j] = SF_startOffsetH1_ff[j];
      SF_startOffsetV1_comb[j] = SF_startOffsetV1_ff[j];        
      SF_startOffsetH2_comb[j] = SF_startOffsetH2_ff[j];
      SF_startOffsetV2_comb[j] = SF_startOffsetV2_ff[j];        
    end

    case (state_ff)
      S_IDLE: begin
        SF_reset1_comb     = 0;
        SF_reset2_comb     = 0;
      end
      S_CAL1: begin
        SF_reset1_comb = 0;
        SF_reset2_comb = 0;
        if (hold) begin
          maxPointH_comb     = 0;
          maxPointV_comb     = 0;
          maxPointValue_comb = 0; 
          SF_reset1_comb = {`rangeH{1'b1}};
          SF_reset2_comb = {`rangeH{1'b1}};
          for (j = 0; j < `rangeH; j = j + 1) begin
            SF_startOffsetH1_comb[j] = `overlapH * j; // notice:
            SF_startOffsetV1_comb[j] = 0;        
            SF_startOffsetH2_comb[j] = `overlapH * j; // notice:
            SF_startOffsetV2_comb[j] = `overlapV;        
          end
        end 
        else if (SF_valid1[0] && (SF_startOffsetV1_ff[0] <= (startV_ff + `possibleV))) begin // update the max point
          if (maxPointValue_ff < SF_sum1[0]) begin
            maxPointH_comb = SF_startH1[0];
            maxPointV_comb = SF_startV1[0];
            maxPointValue_comb = SF_sum1[0];
          end
          SF_startOffsetH1_comb[0] = SF_startOffsetH1_ff[0];
          SF_startOffsetV1_comb[0] = SF_startOffsetV1_ff[0] + `subFrameV;
          SF_reset1_comb[0] = 1;
        end   
        else if (SF_valid1[1] && (SF_startOffsetV1_ff[1] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum1[1]) begin
            maxPointH_comb = SF_startH1[1];
            maxPointV_comb = SF_startV1[1];
            maxPointValue_comb = SF_sum1[1];
          end
          SF_startOffsetV1_comb[1] = SF_startOffsetV1_ff[1] + `subFrameV;
          SF_startOffsetH1_comb[1] = SF_startOffsetH1_ff[1];
          SF_reset1_comb[1] = 1;
        end   
        else if (SF_valid1[2] && (SF_startOffsetV1_ff[2] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum1[2]) begin
            maxPointH_comb = SF_startH1[2];
            maxPointV_comb = SF_startV1[2];
            maxPointValue_comb = SF_sum1[2];
          end
          SF_startOffsetH1_comb[2] = SF_startOffsetH1_ff[2];
          SF_startOffsetV1_comb[2] = SF_startOffsetV1_ff[2] + `subFrameV;
          SF_reset1_comb[2] = 1;
        end
        else if (SF_valid1[3] && (SF_startOffsetV1_ff[3] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum1[3]) begin
            maxPointH_comb = SF_startH1[3];
            maxPointV_comb = SF_startV1[3];
            maxPointValue_comb = SF_sum1[3];
          end
          SF_startOffsetV1_comb[3] = SF_startOffsetV1_ff[3] + `subFrameV;
          SF_startOffsetH1_comb[3] = SF_startOffsetH1_ff[3];
          SF_reset1_comb[3] = 1;
        end   
        else if (SF_valid1[4] && (SF_startOffsetV1_ff[4] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum1[4]) begin
            maxPointH_comb = SF_startH1[4];
            maxPointV_comb = SF_startV1[4];
            maxPointValue_comb = SF_sum1[4];
          end
          SF_startOffsetV1_comb[4] = SF_startOffsetV1_ff[4] + `subFrameV;
          SF_startOffsetH1_comb[4] = SF_startOffsetH1_ff[4];
          SF_reset1_comb[4] = 1;
        end   
        else if (SF_valid1[5] && (SF_startOffsetV1_ff[5] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum1[5]) begin
            maxPointH_comb = SF_startH1[5];
            maxPointV_comb = SF_startV1[5];
            maxPointValue_comb = SF_sum1[5];
          end
          SF_startOffsetH1_comb[5] = SF_startOffsetH1_ff[5];
          SF_startOffsetV1_comb[5] = SF_startOffsetV1_ff[5] + `subFrameV;
          SF_reset1_comb[5] = 1;
        end   
        else if (SF_valid1[6] && (SF_startOffsetV1_ff[6] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum1[6]) begin
            maxPointH_comb = SF_startH1[6];
            maxPointV_comb = SF_startV1[6];
            maxPointValue_comb = SF_sum1[6];
          end
          SF_startOffsetV1_comb[6] = SF_startOffsetV1_ff[6] + `subFrameV;
          SF_startOffsetH1_comb[6] = SF_startOffsetH1_ff[6];
          SF_reset1_comb[6] = 1;
        end
        else if (SF_valid2[0] && (SF_startOffsetV2_ff[0] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[0]) begin
            maxPointH_comb = SF_startH2[0];
            maxPointV_comb = SF_startV2[0];
            maxPointValue_comb = SF_sum2[0];
          end
          SF_startOffsetH2_comb[0] = SF_startOffsetH2_ff[0];
          SF_startOffsetV2_comb[0] = SF_startOffsetV2_ff[0] + `subFrameV;
          SF_reset2_comb[0] = 1;
        end   
        else if (SF_valid2[1] && (SF_startOffsetV2_ff[1] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[1]) begin
            maxPointH_comb = SF_startH2[1];
            maxPointV_comb = SF_startV2[1];
            maxPointValue_comb = SF_sum2[1];
          end
          SF_startOffsetV2_comb[1] = SF_startOffsetV2_ff[1] + `subFrameV;
          SF_startOffsetH2_comb[1] = SF_startOffsetH2_ff[1];
          SF_reset2_comb[1] = 1;
        end   
        else if (SF_valid2[2] && (SF_startOffsetV2_ff[2] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[2]) begin
            maxPointH_comb = SF_startH2[2];
            maxPointV_comb = SF_startV2[2];
            maxPointValue_comb = SF_sum2[2];
          end
          SF_startOffsetH2_comb[2] = SF_startOffsetH2_ff[2];
          SF_startOffsetV2_comb[2] = SF_startOffsetV2_ff[2] + `subFrameV;
          SF_reset2_comb[2] = 1;
        end   
        else if (SF_valid2[3] && (SF_startOffsetV2_ff[3] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[3]) begin
            maxPointH_comb = SF_startH2[3];
            maxPointV_comb = SF_startV2[3];
            maxPointValue_comb = SF_sum2[3];
          end
          SF_startOffsetH2_comb[3] = SF_startOffsetH2_ff[3];
          SF_startOffsetV2_comb[3] = SF_startOffsetV2_ff[3] + `subFrameV;
          SF_reset2_comb[3] = 1;
        end   
        else if (SF_valid2[4] && (SF_startOffsetV2_ff[4] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[4]) begin
            maxPointH_comb = SF_startH2[4];
            maxPointV_comb = SF_startV2[4];
            maxPointValue_comb = SF_sum2[4];
          end
          SF_startOffsetH2_comb[4] = SF_startOffsetH2_ff[4];
          SF_startOffsetV2_comb[4] = SF_startOffsetV2_ff[4] + `subFrameV;
          SF_reset2_comb[4] = 1;
        end   
        else if (SF_valid2[5] && (SF_startOffsetV2_ff[5] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[5]) begin
            maxPointH_comb = SF_startH2[5];
            maxPointV_comb = SF_startV2[5];
            maxPointValue_comb = SF_sum2[5];
          end
          SF_startOffsetH2_comb[5] = SF_startOffsetH2_ff[5];
          SF_startOffsetV2_comb[5] = SF_startOffsetV2_ff[5] + `subFrameV;
          SF_reset2_comb[5] = 1;
        end   
        else if (SF_valid2[6] && (SF_startOffsetV2_ff[6] <= (startV_ff + `possibleV))) begin
          if (maxPointValue_ff < SF_sum2[6]) begin
            maxPointH_comb = SF_startH2[6];
            maxPointV_comb = SF_startV2[6];
            maxPointValue_comb = SF_sum2[6];
          end
          SF_startOffsetH2_comb[6] = SF_startOffsetH2_ff[6];
          SF_startOffsetV2_comb[6] = SF_startOffsetV2_ff[6] + `subFrameV;
          SF_reset2_comb[6] = 1;
        end
      end
      S_UPDATE: begin // update the previous point and the next detecting range
        maxPointValue_comb = 0;
        prePointH_comb = maxPointH_ff;
        prePointV_comb = maxPointV_ff;
        SF_reset1_comb = {`rangeH{1'b1}};
        SF_reset2_comb = {`rangeH{1'b1}};
        startH_comb = maxPointH_ff - `overlapH * 3;
        startV_comb = maxPointV_ff - `overlapV * 3;
        for (j = 0; j < `rangeH; j = j + 1) begin
          SF_startOffsetH1_comb[j] = `overlapH * j; // notice:
          SF_startOffsetV1_comb[j] = 0;        
          SF_startOffsetH2_comb[j] = `overlapH * j; // notice:
          SF_startOffsetV2_comb[j] = `overlapV;        
        end      
      end
      default: begin
        maxPointH_comb = maxPointH_ff;
        maxPointV_comb = maxPointV_ff;
        maxPointValue_comb = maxPointValue_ff;
        prePointH_comb = prePointH_ff;
        prePointV_comb = prePointV_ff;  
        for (j = 0; j < `rangeH; j = j + 1) begin
          SF_startOffsetH1_comb[j] = SF_startOffsetH1_ff[j];
          SF_startOffsetV1_comb[j] = SF_startOffsetV1_ff[j];        
          SF_startOffsetH2_comb[j] = SF_startOffsetH2_ff[j];
          SF_startOffsetV2_comb[j] = SF_startOffsetV2_ff[j];        
        end
      end      
    endcase          
  end

  // =========================================
  // Sequential block
  // =========================================
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
      pixelVAL <= 0;
    else begin
      if (i_pixelVAL)
        pixelVAL <= 1;
      else
        pixelVAL <= 0;
    end
  end
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
      hold <= 0;
    else begin
      if (i_hold)
        hold <= 1;
      else
        hold <= 0;
    end
  end
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      pixelGrade_ff <= 0;
      pixelGradeVAL_ff <= 0;
    end
    else begin
      if (i_pixelVAL) begin
        if (iB_R > iB_G)
          pixelGrade_ff <= {(iB_G > 40), 1'b0};
        else if (iB_G > iB_R)
          pixelGrade_ff <= {(iB_R > 40), 1'b0};
        else if (iR_G > iR_B)
          pixelGrade_ff <= {1'b0, (iR_B > 90)};
        else if (iR_B > iR_G)
          pixelGrade_ff <= {1'b0, (iR_G > 90)};
        else
          pixelGrade_ff <= pixelGrade_ff;
        pixelGradeVAL_ff <= 1;
      end
      else begin
        pixelGrade_ff <= pixelGrade_ff;
        pixelGradeVAL_ff <= 0;
      end
    end
  end
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      Hcnt_ff <= 0;
      Vcnt_ff <= 1;
    end
    else begin
      if (i_pixelVAL) begin
        if (Hcnt_ff < totalH) begin
          Vcnt_ff <= Vcnt_ff;
          Hcnt_ff <= Hcnt_ff + 1;
        end
        else begin
          Hcnt_ff <= 1;
          if (Vcnt_ff < totalV)
            Vcnt_ff <= Vcnt_ff + 1;
          else
            Vcnt_ff <= 1;
        end
      end
      else begin
        Hcnt_ff <= Hcnt_ff;
        Vcnt_ff <= Vcnt_ff;
      end
    end
  end
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
      isTracking <= 0;
    else begin
      isTracking <= isTracking;
      if (i_start)
        isTracking <= 1;
      else if (state_ff == S_CAL1) begin
        if (findRed1 != 0 || findRed2 != 0 || hold)
          isTracking <= 0;
      end
      else if (state_ff == S_UPDATE)
        isTracking <= 1;
    end    
  end
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      state_ff         <= S_IDLE;
      // pixelGrade_ff    <= 0;
      prePointH_ff     <= totalH_half;
      prePointV_ff     <= totalV_half;
      maxPointH_ff     <= 0;
      maxPointV_ff     <= 0;
      maxPointValue_ff <= 0;
      // Hcnt_ff          <= 1;
      // Vcnt_ff          <= 1;
      SF_reset1_ff     <= {`rangeH{1'b1}};
      SF_reset2_ff     <= {`rangeH{1'b1}};
      startH_ff        <= totalH_half - `overlapH * 3; // notice
      startV_ff        <= totalV_half - `overlapV * 3;
      pointGenerated_ff  <= 0;
      updateTriggered_ff <= 0;
      // pixelGradeVAL_ff <= 0;
      for (i = 0; i < `rangeH; i = i + 1) begin
        SF_startOffsetH1_ff[i] <= `overlapH * i;
        SF_startOffsetV1_ff[i] <= 0;
        SF_startOffsetH2_ff[i] <= `overlapH * i;
        SF_startOffsetV2_ff[i] <= `overlapV;
      end
    end
    else begin
      state_ff         <= state_comb;
      // pixelGrade_ff    <= pixelGrade_comb;
      prePointH_ff     <= prePointH_comb;
      prePointV_ff     <= prePointV_comb;
      maxPointH_ff     <= maxPointH_comb;
      maxPointV_ff     <= maxPointV_comb;
      maxPointValue_ff <= maxPointValue_comb;
      // Hcnt_ff          <= Hcnt_comb;
      // Vcnt_ff          <= Vcnt_comb;
      SF_reset1_ff     <= SF_reset1_comb;
      SF_reset2_ff     <= SF_reset2_comb;
      startH_ff        <= startH_comb;
      startV_ff        <= startV_comb;
      // pixelGradeVAL_ff <= (i_pixelVAL)? 1: 0;
      pointGenerated_ff  <= pointGenerated_comb;
      updateTriggered_ff <= updateTriggered_comb;
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
  input i_dataVAL,
  output o_valid,
  output [7:0] o_sum,
  output o_findRed
);
  reg [ 12:0] acc, accR;
  reg valid;
  assign o_sum = acc[12:5];     // 要除多少??
  assign o_valid = valid;
  assign o_findRed = (accR > 30);
  
  always_ff @(posedge i_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      acc   <= 0;
      accR  <= 0;
      valid <= 0;
    end
    else begin
      acc  <= acc;
      accR <= accR;
      valid <= (i_h >= istart_h + `subFrameH) && (i_v >= istart_v + `subFrameV - 1) ? 1: valid;
      if (i_dataVAL) begin
        if ((i_h >= istart_h && i_h < istart_h + `subFrameH)
          && (i_v >= istart_v && i_v < istart_v + `subFrameV)) begin
          acc  <= acc  + {12'b0, idata[1]};
          accR <= accR + {12'b0, idata[0]};
        end
      end
    end
endmodule