# Expresso ASIC 

Fully open source Ethernet focused ASIC chip featuring a 
100Mbps capable cut-through, unmanaged, Ethernet switch. 
This fully open source chip was sponsored by [wafer.space](https://wafer.space/) 
and is part of their second multi-project wafer run. I am deeply grateful for their 
support and this chip might not have existed without them. 

This full chip is targeting the Global Foundries 180 nm process (`gf180mcu`), using the [open source `gf180mcuD` PDK](https://gf180mcu-pdk.readthedocs.io/en/latest/). 

This is the default and preferred 1.94mm × 2.53mm floorplan configuration, targeting a package with 56 pads as well as the smallest `0p5x0p5` wafer.space slot.

![floorplan](docs/chip_pretty.png) 

Features: 
- Ethernet switch:
  - 4x Full duplex Ethernet ports, 100BASE-TX (classic RJ42 cat-3 connection) 
  - Unmanaged switch 
  - Cut-though forwarding
- Heat death of the Universe counter:
  - Broadcasts an Ethernet Frame over the local network ever 1s
  - 100Mbps Ethernet compatible, 100BASE-TX
  - Our solar system will have been engulfed by the sun before it overflows 


## Coffee-shop family 

This full chip ties together in a single package multiple projects that are all part of larger family of open-source Ethernet connected IP: 
- [`coffeepot` first generation switch.](https://github.com/Essenceia/ethernet_switch_asic) - included 
- [`teapot` Ethernet wrapper for building network connected accelerators.](https://github.com/Essenceia/Teapot)
- [`coldbrew` Ethernet connected beacon for broadcasting an ethernet frame with an uptime count until the heat death of the universe.](https://github.com/Essenceia/Until_Heat_Death_Do_Us_Part) - included

These IP's have been scalled up to make the best use of a full chip tapeout, checkout the `src/` folder where the submodules live to see the version of the IP is being used.  

## Pinouts 

Since the LAN8720A PHY chip directly supports IO volatages between +1.62V and +3.6V, in order to be easily compatible, our ASIC targets an 
operating volate of 3.3V, which would result in an IO operating also at 3v3. 

The RMII PHY0-3 interfaces are connected to the switch (`coffeepot`), while PHY4 is connected to the beacon (`coldbrew`). 
Both IP share the same power domains, `clk` and `rst_n` signals. 

By default all input pins are pulled down, so in cases where the board doesn't feature a PHY chip connected to a ASIC RMII PHY interface
no additional changes are needed. All output pins are also pull down. 

![pins](/docs/pin_mapping.svg) 

### External PHY chip 

The pin mapping on this `0p5x0p5` slot was specifically designed for unobstructed routing on the pcb between this ASIC and the LAN8720A chip. 

![lan](/docs/lan8720a_pinout.png) 

Although it might sound at first like narrow targeting of a single part this mapping would also be compatible with the other RMII parts like the `KSZ8081RNA/RND`.

## Future improvements 

This is chip is part of a larger ongoing project to develop fully open source ethernet focused ASICs. 
Future improvements will be focused on working towards a more powerfull and larger version of the switch. 

Short-term changes: 
- Refactor shared Ethernet IP into a seperate library 
- Add formal validation framework

Mid-term changes: 
- design custom FPGA board for accurate device emulation
- design experimental developpement board with FPGA and final chip support
- design final PCB
- Expand to 76 pad version 
- Expand to more ethernet ports 6-8
- Add perf counters and expose said counters over JTAG
- Expand the number of routing entries
- Add cute GDS art to corners 

Longer-term changes: 
- Integrate analog ethernet PHY into the chip
- Target higher Ethernet bandwidths 

## AI Policy 

No AI was used by me in the development of this chip. 

All code and design decisions are, and will remain, entirely human made. 

## Credits

Thanks to the [Wafer.Space](https://wafer.space/) project, its contributors, and all the community working on open source silicon tools for making this possible.

## License 

This hardware is distributed under the **strongly** reciprocal CERN Open Hardware Licence Version 2 unless
otherwise specified.
