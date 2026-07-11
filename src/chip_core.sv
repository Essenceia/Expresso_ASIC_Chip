// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS,
	localparam PORT_CNT = 3,
	localparam PHY_W    = 2 
    )(
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif
    
    input  wire clk,       // clock
    input  wire rst_n,     // reset (active low)
    
    input  wire [NUM_INPUT_PADS-1:0] input_in,   // Input value
    output wire [NUM_INPUT_PADS-1:0] input_pu,   // Pull-up
    output wire [NUM_INPUT_PADS-1:0] input_pd,   // Pull-down

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,   // Input value
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,  // Output value
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,   // Output enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,   // Input type (0=CMOS Buffer, 1=Schmitt Trigger)
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,   // Slew rate (0=fast, 1=slow)
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,   // Input enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,   // Pull-up
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,   // Pull-down

    inout  wire [NUM_ANALOG_PADS-1:0] analog  // Analog
);

/* Coffeepot 
100Mbps Ethernet switch ASIC */ 
// RX pins
wire [PORT_CNT-1:0]       phy_rx_v;
wire [PORT_CNT-1:0]       phy_rx_err;
wire [PORT_CNT*PHY_W-1:0] phy_rx;	

// TX pins
wire [PORT_CNT-1:0]       phy_tx_v;
wire [PORT_CNT*PHY_W-1:0] phy_tx;

// pin mapping
localparam RMII_IN_W  = 4; 
localparam RMII_OUT_W = 3; 

wire [PORT_CNT*RMII_OUT_W-1:0] bidir_input_unusued; 

genvar i; 
generate 
	for(i = 0; i < PORT_CNT; i = i+1): g_coffeepot_pin_conn
		// in
		assign phy_rx[(i+1)*PHY_W-1-:PHY_W] = input_in[i*RMII_IN_W+PHY_W-1-:PHY_W];
		assign phy_rx_v[i]   = input_in[i*RMII_IN_W+2];
		assign phy_rx_err[i] = input_in[i*RMII_IN_W+3];

		assign input_pu[(i+1)*RMII_IN_W-1-:RMII_IN_W] = {RMII_IN_W{1'b0}};
		assign input_pd[(i+1)*RMII_IN_W-1-:RMII_IN_W] = {RMII_IN_W{1'b1}};
	
		// out 
		assign bidir_out[i*RMII_OUT_W+PHY_W-1-:PHY_W] = phy_tx[(i+1)*PHY_W-1-:PHY_W];
		assign didir_out[i*RMII_OUT_W+2]              = phy_tx_v[i];

		assign bidir_oe[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b1}};
		assign bidir_cs[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_sl[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_ie[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_pu[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_pd[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b1}};

		assign bidir_input_unusued[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = bidir_in[(i+1)*RMII_OUT_W-1-:RMII_OUT_W];
	end
endgenerate 

// tie unused pins, TODO cleanup
localparam OUT_PADS_CNT = PORT_CNT*RMII_OUT_W;
localparam UNUSED_BIDIR_PADS_CNT = NUM_BIDIR_PADS - OUT_PADS_CNT; 

assign bidir_out[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT] = {UNUSED_BIDIR_PADS_CNT{1'b0}};
assign bidir_oe[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT]  = {UNUSED_BIDIR_PADS_CNT{1'b1}};
assign bidir_cs[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT]  = {UNUSED_BIDIR_PADS_CNT{1'b0}};
assign bidir_sl[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT]  = {UNUSED_BIDIR_PADS_CNT{1'b0}};
assign bidir_ie[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT]  = {UNUSED_BIDIR_PADS_CNT{1'b0}};
assign bidir_pu[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT]  = {UNUSED_BIDIR_PADS_CNT{1'b0}};
assign bidir_pd[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT]  = {UNUSED_BIDIR_PADS_CNT{1'b0}}; // floating pad

coffeepot #(.PORT_CNT(3), .PHY_W(2), .HAS_TX_PHASE(0)) m_coffeeport(
	.clk(clk), 
	.rst_n(rst_n), 

	.tx_phase_i(1'bX),
	
	.phy_rx_v_i(phy_rx),
	.phy_rx_err_i(phy_rx_v),
	.phy_rx_i(phy_rx_err),

	.phy_tx_v_o(phy_tx_v),
	.phy_tx_o(phy_tx)
); 

// TODO coldbrew

endmodule

`default_nettype wire
