# VESP Wishbone Modules
This repository contains Wishbone modules for the VESP project. More information about modules is in the [documentation](https://honeygol-microsystems.github.io/wb-modules/).

## Modules
- XPM RAM
- GPIO
- SOSIF (software-simulator interface)
- PWM
- Input debouncer

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

## License
Copyright (C) 2025 Ondrej Golasowski

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.