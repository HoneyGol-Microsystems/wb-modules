# VESP Wishbone Modules
This repository contains Wishbone modules for the VESP project. More information about modules is in the [documentation](https://honeygol-microsystems.github.io/wb-modules/).

## Modules
- XPM RAM
- GPIO
- SOSIF (software-simulator interface)

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