# SPDX-FileCopyrightText: © 2025 Project Template Contributors
# SPDX-License-Identifier: Apache-2.0

import os
import random
import logging
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, Edge, RisingEdge, FallingEdge, ClockCycles
from cocotb_tools.runner import get_runner

sim = os.getenv("SIM", "icarus")
GATES = os.getenv("GL", False)
pdk_root = os.getenv("PDK_ROOT", Path(__file__).resolve().parent / "../gf180mcu")
pdk = os.getenv("PDK", "gf180mcuD")
scl = os.getenv("SCL", "gf180mcu_fd_sc_mcu7t5v0")
pad = os.getenv("PAD", "gf180mcu_fd_io")
sram = os.getenv("SRAM", "gf180mcu_fd_ip_sram")
slot = os.getenv("SLOT", "1x1")
WAVES = os.getenv("WAVES", "1").lower() in ("true", "yes", "1")

hdl_toplevel = "chip_top_tb"
coldbrew_phy = "3"

import time
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), "../src/coffeepot/test"))
import coffeepot_tests

sys.path.append(os.path.join(os.path.dirname(__file__), "../src/coldbrew/test"))
import coldbrew_tests

async def set_defaults(dut):
    dut.input_PAD.value = 0

async def enable_power(dut):
    dut.VDD.value = 1
    dut.VSS.value = 0

async def start_clock(clock, freq=50):
    """Start the clock @ freq MHz"""
    c = Clock(clock, 1 / freq * 1000, "ns")
    cocotb.start_soon(c.start())

def set_random_seed():
    if "SEED" in os.environ:
        seed = int(os.environ["SEED"].lower().strip())
    else:
        seed = time.time_ns()
    cocotb.log.info(f"random seed {seed}")
    random.seed(seed)

async def reset(reset, active_low=True, time_ns=1000):
    """Reset dut"""
    cocotb.log.info("Reset asserted...")

    reset.value = not active_low
    await Timer(time_ns, "ns")
    reset.value = active_low

    cocotb.log.info("Reset deasserted.")


async def start_up(dut):
    """Startup sequence"""
    await set_defaults(dut)
    cocotb.log.info(f"GATES {GATES}")
    if GATES:
        await enable_power(dut)
    await start_clock(dut.clk)
    await reset(dut.rst_n)
    set_random_seed()

@cocotb.test()
async def test_counter(dut):
    """Run the counter test"""

    # Create a logger for this testbench
    logger = logging.getLogger("my_testbench")

    logger.info("Startup sequence...")

    # Start up
    await start_up(dut)

    logger.info("Running the test...")

    # Wait for some time...
    await ClockCycles(dut.clk, 10)

   # Start the counter by setting all inputs to 1
    dut.input_PAD.value = 0

    # Wait for a number of clock cycles
    await ClockCycles(dut.clk, 100)

    logger.info("Done!")

# Coffeepot (switch) tb's 

@cocotb.test()
async def coffeepot_simple_broadcast_test(dut):
    await start_up(dut) 
    await coffeepot_tests.simple_unicast_test_sequence(dut)

@cocotb.test()
async def coffeepot_checking_broadcast_test(dut):
    await start_up(dut)
    await coffeepot_tests.checking_broadcast_test_sequence(dut)

@cocotb.test()
async def coffeepot_simple_unicast_test(dut):
    await start_up(dut) 
    await coffeepot_tests.simple_unicast_test_sequence(dut)

@cocotb.test()
async def coffeepot_table_entry_expire_test(dut):
    await start_up(dut) 
    await coffeepot_tests.table_entry_expire_test_sequence(dut)

@cocotb.test()
async def coffeepot_table_multialloc_test(dut): 
    await start_up(dut) 
    coffeepot_module = dut.chip_top.i_chip_core.m_coffeepot
    await coffeepot_tests.table_multialloc_test_sequence(dut, coffeepot_module)

@cocotb.test()
async def coffeepot_table_realloc_test(dut): 
    await start_up(dut) 
    coffeepot_module = dut.chip_top.i_chip_core.m_coffeepot
    await coffeepot_tests.table_realloc_test_sequence(dut, coffeepot_module )

# sim only tests: need accurate tracking of entry liveness to prevent fausle failes
@cocotb.test(skip=True if GATES else False)
async def coffeepot_table_stress_read(dut):
    await start_up(dut)
    cocotb.log.info(type(dut.chip_top))
    coffeepot_module = dut.chip_top.i_chip_core.m_coffeepot
    await coffeepot_tests.table_stress_read_sequence(dut, coffeepot_module)

@cocotb.test()
async def coffeepot_no_rebroadcsat_on_incomming_test(dut):
    await start_up(dut)
    await coffeepot_tests.no_rebroadcsat_on_incomming_test_sequence(dut)

@cocotb.test()
async def coffeepot_close_rx_packets_test(dut):
    await start_up(dut)
    await coffeepot_tests.close_rx_packets_test_sequence(dut)

# Coldbrew (heat death of the universe beacon) tb's
# Tests are dissabled for gate level since real counter width is used 
# and this would cause the test to need to simulate a full 1s to see a 
# single packets
@cocotb.test(skip=True if GATES else False)
async def coldbrew_simple_tx_test(dut):
    await start_up(dut)
    await coldbrew_tests.simple_tx_test_sequence(dut, phy_idx = coldbrew_phy)    

@cocotb.test(skip=True if GATES else False)
async def coldbrew_update_eth_config(dut):
    await start_up(dut)
    coldbrew_module = dut.chip_top.i_chip_core.m_coldbrew
    await coldbrew_tests.update_eth_config_sequence(dut, coldbrew_module, phy_idx = coldbrew_phy)


def chip_top_runner():

    proj_path = Path(__file__).resolve().parent

    sources = []
    defines = {f"SLOT_{slot.upper()}": True}
    includes = [proj_path / "../src/"]

    # Set the LibreLane PDK/SCL/PAD defines
    defines[f"PDK_{pdk.replace('-','_')}"] = True
    defines[f"SCL_{scl}"] = True
    defines[f"PAD_{pad}"] = True
    defines[f"SRAM_{sram}"] = False


    sources.append(proj_path / "chip_top_tb.v")
    if GATES:
        # SCL models
        sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / f"{scl}.v")
        if scl != "gf180mcu_as_sc_mcu7t3v3":
            sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / "primitives.v")

        # We use the powered netlist
        sources.append(proj_path / f"../final/pnl/{hdl_toplevel}.pnl.v")

        defines.update({"FUNCTIONAL": True, "USE_POWER_PINS": True})
    else:
        sources.append(proj_path / "../src/chip_top.sv")
        sources.append(proj_path / "../src/chip_core.sv")

        # coffeepot        
        coffeepot_path = proj_path / "../src/coffeepot/src"
        sources.append(coffeepot_path / "coffeepot.v")
        sources.append(coffeepot_path / "aiguilleur.v")
        sources.append(coffeepot_path / "dispatcher.v")
        sources.append(coffeepot_path / "mac_addr_table.v")
        sources.append(coffeepot_path / "switch_mac_rx.v")
        sources.append(coffeepot_path / "switch_mac_tx.v")
        sources.append(coffeepot_path / "rmii.v")
        sources.append(coffeepot_path / "switch.v")
        sources.append(coffeepot_path / "utils.v")
        sources.append(coffeepot_path / "arbitor.v")
        sources.append(coffeepot_path / "lookup.v")
        sources.append(coffeepot_path / "ttnn_timer.v")
        sources.append(coffeepot_path / "replacement_policy.v")

        #coldbrew
        coldbrew_path = proj_path / "../src/coldbrew/src"
        sources.append(coldbrew_path / "broadcast_timer.v")
        sources.append(coldbrew_path / "coldbrew.v")
        sources.append(coldbrew_path / "crc_8.v")
        sources.append(coldbrew_path / "death_of_the_universe_counter.v")
        sources.append(coldbrew_path / "mac_conf.v")
        sources.append(coldbrew_path / "mac_rx.v")
        sources.append(coldbrew_path / "mac_tx.v")
  
        # cocotb sim specific defs to reduce counter sizes and increase tb coverage 
        # applies to both coldbrew and coffeepot
        defines["COCOTB"] = True

    sources += [
        # IO pad models
        Path(pdk_root) / pdk / f"libs.ref/{pad}/verilog/{pad}.v",
        
        # SRAM macros
        #Path(pdk_root) / pdk / f"libs.ref/{sram}/verilog/{sram}__sram512x8m8wm1.v",
        
        # Custom IP
        proj_path / "../ip/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v",
        proj_path / "../ip/gf180mcu_ws_ip__marker/vh/gf180mcu_ws_ip__marker.v",
        proj_path / "../ip/gf180mcu_ws_ip__qrcode_id/vh/gf180mcu_ws_ip__qrcode_id.v",
        proj_path / "../ip/gf180mcu_ws_ip__shuttle_id/vh/gf180mcu_ws_ip__shuttle_id.v",
        proj_path / "../ip/gf180mcu_ws_ip__project_id/vh/gf180mcu_ws_ip__project_id.v",
        
    ]

    build_args = []

    if sim == "icarus":
        # For debugging
        # build_args = ["-Winfloop", "-pfileline=1"]
        pass

    if sim == "verilator":
        build_args = ["--timing", "--trace", "--trace-fst", "--trace-structs"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        always=True,
        includes=includes,
        build_args=build_args,
        waves=WAVES,
    )

    plusargs = []

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="chip_top_tb,",
        plusargs=plusargs,
        waves=WAVES,
    )


if __name__ == "__main__":
    chip_top_runner()
