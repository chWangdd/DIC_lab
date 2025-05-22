//**************************************
// File Name        : vga.sv
// Created Time     : 2025/05/13 18:30
// Last Revised Time: 2025/05/21 17:00
//**************************************
module VGAController (
  input i_rst_n,
  input i_clk,
  input [23:0] i_color,
  output [7:0] o_VGA_R,
  output [7:0] o_VGA_G,
  output [7:0] o_VGA_B,
  output o_V_sync,
  output o_H_sync,
  output o_blank_n

);
  localparam H_front_porch = 16;
  localparam H_back_porch  = 48;
  localparam H_active_area = 640;
  localparam H_sync_pulse  = 96;
  localparam V_front_porch = 10;
  localparam V_back_porch  = 33;
  localparam V_active_area = 480;
  localparam V_sync_pulse  = 2;
  
  parameter S_Sync   = 0;
  parameter S_Bporch = 1;
  parameter S_Active = 2;
  parameter S_Fporch = 3;

  // Registers assignment
  reg [ 9:0] Hcnt_ff, Hcnt_comb; // count from 0~799
  reg [ 9:0] Vcnt_ff, Vcnt_comb; // count from 0~524
  
  reg [ 1:0] Hstate_ff, Hstate_comb, Vstate_ff, Vstate_comb;
  
  // Wires assignment
  assign o_H_sync = (Hstate_ff == S_Sync);
  assign o_V_sync = (Vstate_ff == S_Sync);
  assign o_blank_n = (Hstate_ff == S_Active && Vstate_ff == S_Active);
  assign o_VGA_R = i_color[ 7: 0];
  assign o_VGA_G = i_color[15: 8];
  assign o_VGA_B = i_color[23:16];
  // Horizonal State Comb. Block
  always_comb begin
    // usual case
    Hstate_comb = Hstate_ff;
    Hcnt_comb = Hcnt_ff + 1;
    case(Hstate_ff)
      S_Fporch: begin // front porch to sync
        if (Hcnt_ff >= H_front_porch) begin
          Hstate_comb = S_Sync;
          Hcnt_comb = 1;
        end 
      end
      S_Sync: begin  // sync to back porch
        if (Hcnt_ff >= H_sync_pulse) begin
          Hstate_comb = S_Bporch;
          Hcnt_comb = 1;
      end 
      end
      S_Bporch: begin // back porch to active
        if (Hcnt_ff >= H_back_porch) begin
          Hstate_comb = S_Active;
          Hcnt_comb = 1;
      end
      end
      S_Active: begin // active to front porch
        if (Hcnt_ff >= H_active_area) begin 
          Hstate_comb = S_Fporch;
          Hcnt_comb = 1;
        end
      end
    endcase
  end

  // Vertical State Comb. Block
  always_comb begin
    // usual case
    Vstate_comb = Vstate_ff;
    Vcnt_comb = Vcnt_ff;

    // vcnt add when horizonal cnt has count to 640 in Active mode
    if (Hstate_ff == S_Active && Hcnt_ff == H_active_area) begin 
      Vcnt_comb = Vcnt_ff + 1;
      case(Vstate_ff)
        S_Fporch: begin // front porch to sync
          if (Vcnt_ff >= V_front_porch) begin
            Vstate_comb = S_Sync;
            Vcnt_comb = 1;
          end 
        end
        S_Sync: begin  // sync to back porch
          if (Vcnt_ff >= V_sync_pulse) begin
            Vstate_comb = S_Bporch;
            Vcnt_comb = 1;
        end 
        end
        S_Bporch: begin // back porch to active
          if (Vcnt_ff >= V_back_porch) begin
            Vstate_comb = S_Active;
            Vcnt_comb = 1;
        end
        end
        S_Active: begin // active to front porch
          if (Vcnt_ff >= V_active_area) begin 
            Vstate_comb = S_Fporch;
            Vcnt_comb = 1;
          end
        end
      endcase
    end
  end

  // Sequential block
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      Hcnt_ff   <= 1;
      Vcnt_ff   <= 1;
      Hstate_ff <= S_Fporch;
      Vstate_ff <= S_Fporch;
    end
    else begin
      Hcnt_ff   <= Hcnt_comb;
      Vcnt_ff   <= Vcnt_comb;
      Hstate_ff <= Hstate_comb;
      Vstate_ff <= Vstate_comb;
    end
  end
endmodule