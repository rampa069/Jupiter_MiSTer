//============================================================================
//  Jupiter Ace replica for MiSTer
//  Copyright (C) 2018-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

`default_nettype none

module guest_top(
	input         CLOCK_27,
`ifdef USE_CLOCK_50
	input         CLOCK_50,
`endif

	output        LED,
	output [VGA_BITS-1:0] VGA_R,
	output [VGA_BITS-1:0] VGA_G,
	output [VGA_BITS-1:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

`ifdef USE_HDMI
	output        HDMI_RST,
	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_PCLK,
	output        HDMI_DE,
	inout         HDMI_SDA,
	inout         HDMI_SCL,
	input         HDMI_INT,
`endif

	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,    // data_io
	input         SPI_SS3,    // OSD
	input         CONF_DATA0, // SPI_SS for user_io

`ifdef USE_QSPI
	input         QSCK,
	input         QCSn,
	inout   [3:0] QDAT,
`endif
`ifndef NO_DIRECT_UPLOAD
	input         SPI_SS4,
`endif

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,

`ifdef DUAL_SDRAM
	output [12:0] SDRAM2_A,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_DQML,
	output        SDRAM2_DQMH,
	output        SDRAM2_nWE,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nCS,
	output  [1:0] SDRAM2_BA,
	output        SDRAM2_CLK,
	output        SDRAM2_CKE,
`endif

	output        AUDIO_L,
	output        AUDIO_R,
`ifdef I2S_AUDIO
	output        I2S_BCK,
	output        I2S_LRCK,
	output        I2S_DATA,
`endif
`ifdef SPDIF_AUDIO
	output        SPDIF,
`endif
`ifdef USE_AUDIO_IN
	input         AUDIO_IN,
`endif
	input         UART_RX,
	output        UART_TX

);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

`ifdef USE_AUDIO_IN
wire TAPE_SOUND = AUDIO_IN;
`else
wire TAPE_SOUND = UART_RX;
`endif

assign LED  = !ioctl_download;



`include "build_id.v"
parameter CONF_STR = {
	"Jupiter;;",
	"-;",
	"F,DCE;",
	"-;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"-;",
	"O45,CPU Speed,Normal,x2,x4;",
	"T0,Reset;",
	"V,v",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////

wire clk_sys;
wire locked;

pll pll
(
	.inclk0   (CLOCK_27),
	.c0 (clk_sys), // 64 MHz
	.locked (locked)
);

wire [1:0] turbo = status[5:4];

reg ce_pix;
reg ce_cpu;
always @(negedge clk_sys) begin
	reg [3:0] div;

	div <= div + 1'd1;
	ce_pix <= !div[2:0];
	ce_cpu <= (!div[3:0] && !turbo) | (!div[2:0] && turbo[0]) | turbo[1];
end

/////////////////  MIST IO  ///////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire [15:0] joya, joyb;

wire        key_pressed;
wire [7:0]  key_code;
wire        key_strobe;
wire        key_extended;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
reg         ioctl_wait = 0;
wire        scandoubler_disable;
wire        ypbpr;
wire        no_csync;

wire [10:0] ps2_key ={key_strobe,key_pressed,key_extended,key_code};

user_io #(.STRLEN($size(CONF_STR)>>3), .SD_IMAGES(2), .FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14))) user_io
(
	.clk_sys(clk_sys),
	.clk_sd(clk_sys),
	.conf_str(CONF_STR),

	.SPI_CLK(SPI_SCK),
	.SPI_SS_IO(CONF_DATA0),
	.SPI_MOSI(SPI_DI),
	.SPI_MISO(SPI_DO),


	.key_strobe(key_strobe),
	.key_code(key_code),
	.key_pressed(key_pressed),
	.key_extended(key_extended),

	
	.joystick_0(joya),
	.joystick_1(joyb),

	.buttons(buttons),
	.status(status),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.no_csync(no_csync)

);

data_io data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.clkref_n      ( 1'b0         ),
	.ioctl_download( ioctl_download),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

mist_video #(.COLOR_DEPTH(4), .SD_HCNT_WIDTH(10), .USE_BLANKS(1'b1), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD)) mist_video (
	.clk_sys      (clk_sys     ),
	.SPI_SCK      (SPI_SCK    ),
	.SPI_SS3      (SPI_SS3    ),
	.SPI_DI       (SPI_DI     ),
	
	.R({4{video_out}}),
	.G({4{video_out}}),
	.B({4{video_out}}),

	.HSync(~hsync),
	.VSync(~vsync),
	.HBlank(hblank),
	.VBlank(vblank),

	.VGA_R        (VGA_R      ),
	.VGA_G        (VGA_G      ),
	.VGA_B        (VGA_B      ),
	.VGA_VS       (VGA_VS     ),
	.VGA_HS       (VGA_HS     ),
	.ce_divider   (1'b0       ),
	.scandoubler_disable(scandoubler_disable),
	.scanlines    (status[3:1]),
	.ypbpr        (ypbpr      ),
	.no_csync     (no_csync)
 );



wire [15:0] loader_addr  = ioctl_addr +'h2000;
wire  [7:0] loader_data  = ioctl_dout;
wire        loader_wr    = ioctl_wr;
wire        loader_en    = ioctl_download;
wire        loader_reset = ioctl_download;
///////////////////////////////////////////////////

wire reset = !locked | status[0] | buttons[1];

wire mic,spk;

wire [7:0] kbd_row;
wire [4:0] kbd_col;
wire       video_out;

ace ace
(
	.*,
	.clk(clk_sys),
	.no_wait(|turbo),
	.reset(reset|loader_reset)
);

keyboard keyboard (.*);


wire [1:0] scale = status[3:2];

wire [15:0] DAC_L;
assign DAC_L = {1'b0, spk, mic, 13'd0};

wire hsync, vsync, hblank, vblank;

dac #(
   .c_bits	(16))
audiodac_l(
   .clk_i	(clk_sys	),
   .res_n_i	(1	),
   .dac_i	(DAC_L),
   .dac_o	(AUDIO_L)
  );

dac #(
   .c_bits	(16))
audiodac_r(
   .clk_i	(clk_sys	),
   .res_n_i	(1	),
   .dac_i	(DAC_L),
   .dac_o	(AUDIO_R)
  );

wire [31:0] clk_rate =  32'd52_000_000;

`ifdef I2S_AUDIO
//i2s i2s (
//	.reset(1'b0),
//	.clk(clk_sys),
//	.clk_rate(clk_rate),
//
//	.sclk(I2S_BCK),
//	.lrclk(I2S_LRCK),
//	.sdata(I2S_DATA),
//
//	.left_chan (DAC_L),
//	.right_chan(DAC_L)
//);

audio_top audio_top
(
  .clk_50MHz  (CLOCK_27),
  .dac_MCLK   (),
  .dac_LRCK   (I2S_LRCK),
  .dac_SCLK   (I2S_BCK),
  .dac_SDIN   (I2S_DATA),
  .L_data     (DAC_L),
  .R_data     (DAC_L)
);
`endif

endmodule
