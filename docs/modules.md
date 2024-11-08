# Module documentation

## XPM RAM
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

## 32-bit GPIO
This module implements a 32-bit wide GPIO ports.

| Parameter              | Value                                                     |
|------------------------|-----------------------------------------------------------|
| Wishbone revision      | B4                                                        |
| Interface type         | SLAVE                                                     |
| Supported cycles       | SLAVE, (pipelined) READ/WRITE                             |
| Data port size         | 32 bit                                                    |
| Data port granularity  | 32 bit (byte or half word access not supported)           |
| Data port max size     | 32 bit                                                    |
| Data transfer ordering | Little endian                                             |

GPIO consists of 3 registers: direction register, read data register and write data register. GPIO register set is word-addressable only. Only lower 4 bits of address
are decoded. `X` means don't care.

| Address | Access |Register |
| ------- | ------ | ------- |
| 4'b00XX | R/W | direction |
| 4'b01XX | R/W | data to be output on ports |
| 4'b10XX | R   | data read from ports |

Direction register drives all 32 ports, meaning each bit controls one port. Directions are encoded as following:

- `0`: input

- `1`: output

## SOSIF
This block implements an interface between any Wishbone master (e.g. CPU) and an RTL simulator. This block is obviously non-synthesizable.

| Parameter              | Value                                                     |
|------------------------|-----------------------------------------------------------|
| Wishbone revision      | B4                                                        |
| Interface type         | SLAVE                                                     |
| Supported cycles       | SLAVE, READ/WRITE                                         |
| Data port size         | 32 bit                                                    |
| Data port granularity  | 32 bit (byte or half word access not supported)           |
| Data port max size     | 32 bit                                                    |
| Data transfer ordering | Little endian                                             |

### Usage
It is possible to use this interface for example as a way of communication between simulated CPU and an RTL simulator. For now, the interface supports halting the simulation and sending messages to be printed to the log.

The SOSIF is available via a single write-only memory mapped register. Address depends on your interconnect configuration.

The SOSIF is interfaced by writing a word to this address. The word contains a command (OP) and optionally some arguments. Following table describes format of the word for every supported command:

| Command                          | Byte 3 | Byte 2 | Byte 1        | Byte 0 |
|----------------------------------|--------|--------|---------------|--------|
| Halt simulation, no status       | 00     | 00     | 00            | 01     |
| Halt simulation with test passed | 00     | 00     | 00            | 02     |
| Halt simulation with test failed | 00     | 00     | 00            | 03     |
| Put character to msg buffer      | 00     | 00     | <character\>  | 10     |
| Flush buffer with $info          | 00     | 00     | 00            | 11     |
| Flush buffer with $warning       | 00     | 00     | 00            | 12     |
| Flush buffer with $error         | 00     | 00     | 00            | 13     |

Examples:

- To terminate the simulation without any additional message, write `0x00000001`.

- To put character 'A' to a message buffer and then print it using SystemVerilog's `$info`, write `0x00004110` and then `0x00000011`.