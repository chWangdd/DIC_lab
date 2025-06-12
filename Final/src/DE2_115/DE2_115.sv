`define VGA_640x480p60 1

module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO,

	input		    [11:0]		D5M_D,
	input		          		D5M_FVAL,
	input		          		D5M_LVAL,
	input		          		D5M_PIXLCLK,
	output		          		D5M_RESET_N,
	output		          		D5M_SCLK,
	inout		          		D5M_SDATA,
	input		          		D5M_STROBE,
	output		          		D5M_TRIGGER,
	output		          		D5M_XCLKIN

);
// ===================================================
// Registers declarations
// ===================================================
logic key0down, key1down, key2down;
logic CLK_25M;
logic CLK_100M;

logic	[15:0]	Read_DATA1;
logic	[15:0]	Read_DATA2;

logic	[11:0]	mCCD_DATA;
logic			    mCCD_DVAL;
logic			    mCCD_DVAL_d;
logic	[15:0]	X_Cont;
logic	[15:0]	Y_Cont;
logic	[ 9:0]	X_ADDR;
logic	[31:0]	Frame_Cont;
logic			    DLY_RST_0;
logic			    DLY_RST_1;
logic			    DLY_RST_2;
logic			    DLY_RST_3;
logic			    DLY_RST_4;
logic			    Read;
logic	[11:0]	rCCD_DATA;
logic	  			rCCD_LVAL;
logic		  		rCCD_FVAL;
logic	[11:0]	sCCD_R;
logic	[11:0]	sCCD_G;
logic	[11:0]	sCCD_B;
logic			    sCCD_DVAL;

logic	[ 9:0]	oVGA_R;   				//	VGA Red[9:0]
logic	[ 9:0]	oVGA_G;	 				  //	VGA Green[9:0]
logic	[ 9:0]	oVGA_B;   				//	VGA Blue[9:0]
//power on start
logic             auto_start;

logic [11:0] SDRAM_W_G;
logic [11:0] SDRAM_W_B;
logic [11:0] SDRAM_W_R;
logic SDRAM_W_clk, SDRAM_W_en;
// ===================================================
// Wires declarations
// ===================================================

//=======================================================
//  Structural coding
//=======================================================
assign VGA_SYNC_N = 1'b0;
assign VGA_CLK = CLK_25M;
assign D5M_XCLKIN = CLK_25M;
assign sdram_ctrl_clk = CLK_100M ;
// D5M
assign	D5M_TRIGGER	=	1'b1;  // tRIGGER
assign	D5M_RESET_N	=	DLY_RST_1;
assign  VGA_CTRL_CLK = ~VGA_CLK;
assign  VGA_SYNC_N = 1'b0;
assign  VGA_CLK = CLK_25M;

assign	LEDR		=	SW;
assign	LEDG		=	Y_Cont;
assign	UART_TXD = UART_RXD;


// comment those are use for display
assign HEX0 = '1;
assign HEX1 = '1;
assign HEX2 = '1;
assign HEX3 = '1;
assign HEX4 = '1;
assign HEX5 = '1;
assign HEX6 = '1;
assign HEX7 = '1;

//auto start when power on
assign auto_start = ((KEY[0])&&(DLY_RST_3)&&(!DLY_RST_4))? 1'b1:1'b0;

assign SDRAM_W_G = sCCD_G[11:2];
assign SDRAM_W_B = sCCD_B[11:2];
assign SDRAM_W_R = sCCD_R[11:2];
assign SDRAM_W_clk = D5M_PIXLCLK;
assign SDRAM_W_en  = sCCD_DVAL;

//D5M read 
always@(posedge D5M_PIXLCLK)
begin
	rCCD_DATA	<=	D5M_D;
	rCCD_LVAL	<=	D5M_LVAL;
	rCCD_FVAL	<=	D5M_FVAL;
end

Altpll pll0( // generate with qsys, please follow lab2 tutorials
	.clk_clk(CLOCK_50),
	.reset_reset_n(KEY[3]),
	.altpll_25m_clk(CLK_25M),
	.altpll_100m_clk(CLK_100M),
);



// you can decide key down settings on your own, below is just an example
Debounce deb0(
	.i_in(KEY[0]), // Record/Pause
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key0down) 
);

Debounce deb1(
	.i_in(KEY[1]), // Play/Pause
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key1down) 
);

Debounce deb2(
	.i_in(KEY[2]), // Stop
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key2down) 
);

// VGA和SDRAM之間的信號還須修正
Top top0(
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.i_clk_25M(CLK_25M),
	
	// button
	.i_key_0(key0down),
	.i_key_1(key1down),
	.i_key_2(key2down),
	// sdram input
	.i_R(Read_DATA1[9:2]),
	.i_G({Read_DATA1[14:10],Read_DATA2[14:12]}),
	.i_B(Read_DATA2[9:2]),
	// vga
	.o_VGA_R(VGA_R),
	.o_VGA_G(VGA_G),
	.o_VGA_B(VGA_B),
	.o_V_sync(VGA_VS),
	.o_H_sync(VGA_HS),
	.o_VGA_BLANK_N(VGA_BLANK_N),
	.o_request(READ)
);

Sdram_Control	u7	(	//	HOST Side						
						  .RESET_N(KEY[0]),
							.CLK(sdram_ctrl_clk), //clk_100M

							//	FIFO Write Side 1
							.WR1_DATA({1'b0,sCCD_G[11:7],sCCD_B[11:2]}), // {1'b0, SDRAM_W_G[9:5], SDRAM_W_B}
							.WR1(sCCD_DVAL), // SDRAM_W_en
							.WR1_ADDR(0),
						  .WR1_MAX_ADDR(640*480/2),
						  .WR1_LENGTH(8'h50),					
							.WR1_LOAD(!DLY_RST_0),
							.WR1_CLK(D5M_PIXLCLK), //SDAM_W_CLK

							//	FIFO Write Side 2
							.WR2_DATA({1'b0,sCCD_G[6:2],sCCD_R[11:2]}), //{1'b0, SDRAM_W_G[4:0], SDRAM_W_R}
							.WR2(sCCD_DVAL),  // SDRAM_W_en
							.WR2_ADDR(23'h100000),
					    .WR2_MAX_ADDR(23'h100000+640*480/2),
							.WR2_LENGTH(8'h50),
							.WR2_LOAD(!DLY_RST_0),
							.WR2_CLK(D5M_PIXLCLK),

							//	FIFO Read Side 1
					    .RD1_DATA(Read_DATA1),
		        	.RD1(Read),
		        	.RD1_ADDR(0),
						  .RD1_MAX_ADDR(640*480/2),
							.RD1_LENGTH(8'h50),
							.RD1_LOAD(!DLY_RST_0),
							.RD1_CLK(~VGA_CTRL_CLK),
							
							//	FIFO Read Side 2
						  .RD2_DATA(Read_DATA2),
							.RD2(Read),
							.RD2_ADDR(23'h100000),
					    .RD2_MAX_ADDR(23'h100000+640*480/2),
							.RD2_LENGTH(8'h50),
			      	.RD2_LOAD(!DLY_RST_0),
							.RD2_CLK(~VGA_CTRL_CLK),
							
							//	SDRAM Side
					    .SA(DRAM_ADDR),
							.BA(DRAM_BA),
							.CS_N(DRAM_CS_N),
							.CKE(DRAM_CKE),
							.RAS_N(DRAM_RAS_N),
							.CAS_N(DRAM_CAS_N),
							.WE_N(DRAM_WE_N),
							.DQ(DRAM_DQ),
							.DQM(DRAM_DQM)
						);
// D5M image capture
// 按KEY3重新開啟
// 按KEY2會停止
// 輸出為12bits data
// x => 0 ~ 2591
// y => 0 ~ 1943
CCD_Capture			u3	(	.oDATA(mCCD_DATA),
							.oDVAL(mCCD_DVAL),
							.oX_Cont(X_Cont),
							.oY_Cont(Y_Cont),
							.oFrame_Cont(Frame_Cont),
							.iDATA(rCCD_DATA),
							.iFVAL(rCCD_FVAL),
							.iLVAL(rCCD_LVAL),
							.iSTART(!KEY[3]|auto_start),
							.iEND(!KEY[2]),
							.iCLK(~D5M_PIXLCLK), // missing 
							.iRST(DLY_RST_2)
						);
//D5M I2C control
I2C_CCD_Config 		u8	(	//	Host Side
							.iCLK(CLOCK2_50), // missing 
							.iRST_N(DLY_RST_2),
							.iEXPOSURE_ADJ(KEY[1]),
							.iEXPOSURE_DEC_p(SW[0]),
							.iZOOM_MODE_SW(SW[16]),
							//	I2C Side
							.I2C_SCLK(D5M_SCLK),
							.I2C_SDAT(D5M_SDATA)
						);
//D5M raw date convert to RGB data
RAW2RGB				u4	(	.iCLK(D5M_PIXLCLK), // missing 
							.iRST(DLY_RST_1),
							.iDATA(mCCD_DATA),
							.iDVAL(mCCD_DVAL),
							.oRed(sCCD_R),
							.oGreen(sCCD_G),
							.oBlue(sCCD_B),
							.oDVAL(sCCD_DVAL),
							.iX_Cont(X_Cont),
							.iY_Cont(Y_Cont)
						);
//Reset module
Reset_Delay			u2	(	.iCLK(CLOCK2_50),
							.iRST(KEY[0]),
							.oRST_0(DLY_RST_0),
							.oRST_1(DLY_RST_1),
							.oRST_2(DLY_RST_2),
							.oRST_3(DLY_RST_3),
							.oRST_4(DLY_RST_4)
						);

//Frame count display
// SEG7_LUT_8 			u5	(	.oSEG0(HEX0),.oSEG1(HEX1),
// 							.oSEG2(HEX2),.oSEG3(HEX3),
// 							.oSEG4(HEX4),.oSEG5(HEX5),
// 							.oSEG6(HEX6),.oSEG7(HEX7),
// 							.iDIG(Frame_Cont[31:0])
// 						);
//VGA DISPLAY
// VGA_Controller		u1	(	//	Host Side
// 							.oRequest(Read),
// 							.iRed(Read_DATA2[9:0]),
// 							.iGreen({Read_DATA1[14:10],Read_DATA2[14:10]}),
// 							.iBlue(Read_DATA1[9:0]),
// 							//	VGA Side
// 							.oVGA_R(oVGA_R),
// 							.oVGA_G(oVGA_G),
// 							.oVGA_B(oVGA_B),
// 							.oVGA_H_SYNC(VGA_HS),
// 							.oVGA_V_SYNC(VGA_VS),
// 							.oVGA_SYNC(VGA_SYNC_N),
// 							.oVGA_BLANK(VGA_BLANK_N),
// 							//	Control Signal
// 							.iCLK(VGA_CTRL_CLK),
// 							.iRST_N(DLY_RST_2),
// 							.iZOOM_MODE_SW(SW[16])
// 						);

endmodule
