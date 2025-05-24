`define vga_640x480p60        // 25MHz    VGA clock
// `define vga_1024x768p43       // 44.9MHz  VGA clock
// `define vga_1024x768p60       // 65 MHz   VGA clock
// `define vga_1280x960p60       // 102.1MHz VGA clock

`ifdef vga_640x480p60
  localparam H_front_porch = 16;
  localparam H_back_porch  = 48;
  localparam H_active_area = 640;
  localparam H_sync_pulse  = 96;

  localparam V_front_porch = 10;
  localparam V_back_porch  = 33;
  localparam V_active_area = 480;
  localparam V_sync_pulse  = 2; 

`elsif vga_1024x768p43
  localparam H_front_porch = 8;
  localparam H_back_porch  = 56;
  localparam H_active_area = 1024;
  localparam H_sync_pulse  = 176;

  localparam V_front_porch = 0;
  localparam V_back_porch  = 41;
  localparam V_active_area = 768;
  localparam V_sync_pulse  = 8; 

`elsif vga_1024x768p60
  localparam H_front_porch = 24;
  localparam H_back_porch  = 160;
  localparam H_active_area = 1024;
  localparam H_sync_pulse  = 136;

  localparam V_front_porch = 3;
  localparam V_back_porch  = 29;
  localparam V_active_area = 768;
  localparam V_sync_pulse  = 6; 

`elsif vga_1280x960p60
  localparam H_front_porch = 80;
  localparam H_back_porch  = 216;
  localparam H_active_area = 1280;
  localparam H_sync_pulse  = 136;

  localparam V_front_porch = 1;
  localparam V_back_porch  = 30;
  localparam V_active_area = 960;
  localparam V_sync_pulse  = 3; 

`else
  localparam H_front_porch = 16;
  localparam H_back_porch  = 48;
  localparam H_active_area = 640;
  localparam H_sync_pulse  = 96;
  localparam V_front_porch = 10;
  localparam V_back_porch  = 33;
  localparam V_active_area = 480;
  localparam V_sync_pulse  = 2; 
`endif 