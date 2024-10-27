# VESP Wishbone Modules
This repository contains Wishbone modules for VESP project.

## Modules
Signals are named similarly as in Wishbone specification. This specific naming is determined by a nature of SystemVerilog interfaces -- in ports where direction differs between master and slave, no direction is indicated in the name (except for dat_* signals), because the actual direction is determined by a modport. Here are signal names valid for SLAVE modules:

| Signal name | Wishbone equivalent |
|-------------|---------------------|
| clk_i       | CLK_I               |
| rst_i       | RST_I               |
| adr         | ADR_I               |
| dat_i       | DAT_I               |
| we          | WE_I                |
| sel         | SEL_I               |
| stb         | STB_I               |
| cyc         | CYC_I               |
| dat_o       | DAT_O               |
| ack         | ACK_O               |

### XPM RAM
This module implements a basic parametrizable XPM RAM SLAVE module.

Here are relevant parameters as dictated by Wishbone specification B4:

| Parameter              | Value                                                     |
|------------------------|-----------------------------------------------------------|
| Wishbone revision      | B4                                                        |
| Interface type         | SLAVE                                                     |
| Supported cycles       | SLAVE, READ/WRITE                                         |
| Data port size         | Variable, default 32 bit                                  |
| Data port granularity  | Variable, default 8 bit                                   |
| Data port max size     | Dictated by XPM macro, for 2024.1 version it is 4608 bits |
| Data transfer ordering | Little endian                                             |


## Simulation quickstart
Dependencies:
- Questa Sim (or other sim from the 'big 3', change to FuseSoC core required),
- FuseSoC,
- XPM SystemVerilog models (automatically installed with Vivado).

1. Install all dependencies.
2. Modify `wb_modules.core` with correct path to XPM location.
3. Run:
```sh
fusesoc run --target <target_name> wb-modules
# For example:
fusesoc run --target xpm_ram_tb wb-modules
```

You can find more information in documentation. To build and read docs, install `mkdocs` and run:
```sh
mkdocs build
mkdocs serve
```