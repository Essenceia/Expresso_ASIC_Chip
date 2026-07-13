// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_core #(
`ifdef VERILATOR_LINT
    parameter NUM_INPUT_PADS = 16,
    parameter NUM_BIDIR_PADS = 29,
    parameter NUM_ANALOG_PADS = 1,
`else
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS,
`endif
	localparam PORT_CNT        = 4, // total port cnd
	localparam SWITCH_PORT_CNT = 3,
	localparam PHY_W           = 2,

	localparam MAC_W = 48,
	parameter [MAC_W-1:0] COLDBREW_MAC = 48'h0090CF00CAFE 
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

wire [NUM_BIDIR_PADS-1:0] bidir_input_unused; 

genvar i; 

generate // PHY0, PHY4 : particularly well placed pins
	for(i = 0; i < PORT_CNT ; i = i+3 )begin: g_coffeepot_pin_conn_in_dly
		wire [PHY_W-1:0] phy_rx_next, phy_rx_dly;
		wire             phy_rx_v_next, phy_rx_v_dly;
		wire             phy_rx_err_next, phy_rx_err_dly;
		// in
		assign phy_rx_next[PHY_W-1:0] = input_in[i*RMII_IN_W+PHY_W-1-:PHY_W];
		assign phy_rx_v_next          = input_in[i*RMII_IN_W+2];
		assign phy_rx_err_next        = input_in[i*RMII_IN_W+3];

		`ifdef SCL_gf180mcu_fd_sc_mcu7t5v0
		gf180mcu_fd_sc_mcu7t5v0__dlyb_1 m_dly_phy_rx_0(
			.I(phy_rx_next[0]),
			.Z(phy_rx_dly[0]));
		gf180mcu_fd_sc_mcu7t5v0__dlyb_1 m_dly_phy_rx_1(
			.I(phy_rx_next[1]),
			.Z(phy_rx_dly[1]));
		gf180mcu_fd_sc_mcu7t5v0__dlyb_1 m_dly_phy_rx_v(
	        .I(phy_rx_v_next),
	        .Z(phy_rx_v_dly));
		gf180mcu_fd_sc_mcu7t5v0__dlyb_1 m_dly_phy_rx_err(
	        .I(phy_rx_err_next),
	        .Z(phy_rx_err_dly));
		`else
		assign phy_rx_dly     = phy_rx_next; 
		assign phy_rx_v_dly   = phy_rx_v_next; 
		assign phy_rx_err_dly = phy_rx_err_next; 
		`endif
		assign phy_rx[(i+1)*PHY_W-1-:PHY_W] = phy_rx_dly;
		assign phy_rx_v[i]                  = phy_rx_v_dly;
		assign phy_rx_err[i]                = phy_rx_err_dly;
endgenerate


generate // PHY1, PHY2 
	for(i = 1; i < 3; i = i+1 )begin: g_coffeepot_pin_conn_in_no_dly
		// in
		assign phy_rx[(i+1)*PHY_W-1-:PHY_W] = input_in[i*RMII_IN_W+PHY_W-1-:PHY_W];
		assign phy_rx_v[i]   = input_in[i*RMII_IN_W+2];
		assign phy_rx_err[i] = input_in[i*RMII_IN_W+3];
endgenerate

generate 
	for(i = 0; i < PORT_CNT; i = i+1)begin: g_coffeepot_pin_conn_in_common		
		assign input_pu[(i+1)*RMII_IN_W-1-:RMII_IN_W] = {RMII_IN_W{1'b0}};
		assign input_pd[(i+1)*RMII_IN_W-1-:RMII_IN_W] = {RMII_IN_W{1'b1}};
endgenerate 

generate 
	for(i = 0; i < PORT_CNT; i = i+1)begin: g_coffeepot_pin_conn_out
	
		// out 
		assign bidir_out[i*RMII_OUT_W+PHY_W-1-:PHY_W] = phy_tx[(i+1)*PHY_W-1-:PHY_W];
		assign bidir_out[i*RMII_OUT_W+2]              = phy_tx_v[i];

		assign bidir_oe[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b1}};
		assign bidir_cs[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_sl[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_ie[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_pu[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b0}};
		assign bidir_pd[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = {RMII_OUT_W{1'b1}};

		assign bidir_input_unused[(i+1)*RMII_OUT_W-1-:RMII_OUT_W] = bidir_in[(i+1)*RMII_OUT_W-1-:RMII_OUT_W];
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

assign bidir_input_unused[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT] = bidir_in[NUM_BIDIR_PADS-1-:UNUSED_BIDIR_PADS_CNT];

/* Insert delay depending for particularly well placed pins to fix hold
 * violations */
wire rst_n_dly;
`ifdef SCL_gf180mcu_fd_sc_mcu7t5v0
gf180mcu_fd_sc_mcu7t5v0__dlyb_1 m_dly_rst_n(
        .I(rst_n),
        .Z(rst_n_dly)
);
`else
assign rst_n_dly = rst_n; 
`endif


coffeepot #(.PORT_CNT(SWITCH_PORT_CNT), .PHY_W(PHY_W), .HAS_TX_PHASE(0)) m_coffeepot(
	.clk(clk), 
	.rst_n(rst_n_dly), 

	.tx_phase_i(1'bX),
	
	.phy_rx_v_i(phy_rx_v[SWITCH_PORT_CNT-1:0]),
	.phy_rx_err_i(phy_rx_err[SWITCH_PORT_CNT-1:0]),
	.phy_rx_i(phy_rx[PHY_W*SWITCH_PORT_CNT-1:0]),

	.phy_tx_v_o(phy_tx_v[SWITCH_PORT_CNT-1:0]),
	.phy_tx_o(phy_tx[PHY_W*SWITCH_PORT_CNT-1:0])
); 

coldbrew #(.PHY_W(2), .HAS_TX_PHASE(0), .DEFAULT_MAC(COLDBREW_MAC)) m_coldbrew(
	.clk(clk), 
	.rst_n(rst_n), 

	.tx_phase_i(1'bX),
	
	.phy_rx_v_i(phy_rx_v[PORT_CNT-1]),
	.phy_rx_err_i(phy_rx_err[PORT_CNT-1]),
	.phy_rx_i(phy_rx[PHY_W*PORT_CNT-1-:PHY_W]),

	.phy_tx_v_o(phy_tx_v[PORT_CNT-1]),
	.phy_tx_o(phy_tx[PHY_W*PORT_CNT-1-:PHY_W])
);

endmodule

`default_nettype wire
