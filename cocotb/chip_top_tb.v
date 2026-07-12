`timescale 1 ns / 1 ps
`default_nettype none

`include "slot_defines.svh"

module chip_top_tb;

localparam NUM_INPUT_PADS  = `NUM_INPUT_PADS; 
localparam NUM_BIDIR_PADS  = `NUM_BIDIR_PADS; 
localparam NUM_ANALOG_PADS = `NUM_ANALOG_PADS;

initial begin
    `ifdef DUMP_WAVEFORMS
        $dumpfile("chip_top_tb.fst");
        $dumpvars(0, chip_top_tb);
    `endif
end

`ifdef USE_POWER_PINS
wire VDD;
wire VSS;
wire DVDD;
wire DVSS;
`endif

wire clk;
wire rst_n;

wire [NUM_INPUT_PADS-1:0]  input_PAD;
wire [NUM_BIDIR_PADS-1:0]  bidir_PAD; 
wire [NUM_ANALOG_PADS-1:0] analog_PAD; 

// cocotb lacks support for verilog array indexing
// Coffeepot switch pins 
// RX0 path
wire [1:0] phy_rx0;
wire       phy_rx0_v;
wire       phy_rx0_err;
// RX1
wire [1:0] phy_rx1;
wire       phy_rx1_v;
wire       phy_rx1_err;
// RX2
wire [1:0] phy_rx2;
wire       phy_rx2_v;
wire       phy_rx2_err;
// RX3
wire [1:0] phy_rx3;
wire       phy_rx3_v;
wire       phy_rx3_err;	

// TX0 
wire [1:0] phy_tx0;
wire       phy_tx0_v;
// TX1
wire [1:0] phy_tx1;
wire       phy_tx1_v;
// TX2 
wire [1:0] phy_tx2;
wire       phy_tx2_v;
// TX3
wire [1:0] phy_tx3;
wire       phy_tx3_v;

// expresso chip top
// PHY[2-0] coffeepot 
// PHY[3]   coldbrew
assign input_PAD[1:0]   = phy_rx0;
assign input_PAD[2]     = phy_rx0_v;
assign input_PAD[3]     = phy_rx0_err;

assign input_PAD[5:4]   = phy_rx1;
assign input_PAD[6]     = phy_rx1_v;
assign input_PAD[7]     = phy_rx1_err;

assign input_PAD[9:8]   = phy_rx2;
assign input_PAD[10]    = phy_rx2_v;
assign input_PAD[11]    = phy_rx2_err;

assign input_PAD[13:12] = phy_rx3;
assign input_PAD[14]    = phy_rx3_v;
assign input_PAD[15]    = phy_rx3_err;

assign phy_tx0     = bidir_PAD[1:0];
assign phy_tx0_v   = bidir_PAD[2];

assign phy_tx1     = bidir_PAD[4:3];
assign phy_tx1_v   = bidir_PAD[5];

assign phy_tx2     = bidir_PAD[7:6];
assign phy_tx2_v   = bidir_PAD[8];

assign phy_tx3     = bidir_PAD[10:9];
assign phy_tx3_v   = bidir_PAD[11];

chip_top chip_top (
    `ifdef USE_POWER_PINS
    .VDD,
    .VSS,
    .DVDD,
    .DVSS,
    `endif

    .clk_PAD(clk),
    .rst_n_PAD(rst_n),
        
	.input_PAD(input_PAD), 
	.bidir_PAD(bidir_PAD),
	.analog_PAD(analog_PAD)
);

endmodule

`default_nettype wire
