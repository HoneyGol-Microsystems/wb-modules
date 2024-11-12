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

## PWM
This block implements very simple 12-bit PWM outputs.

| Parameter              | Value                                                     |
|------------------------|-----------------------------------------------------------|
| Wishbone revision      | B4                                                        |
| Interface type         | SLAVE                                                     |
| Supported cycles       | SLAVE, (pipelined) READ/WRITE                             |
| Data port size         | 32 bit                                                    |
| Data port granularity  | 32 bit (byte or half word access not supported)           |
| Data port max size     | 32 bit                                                    |
| Data transfer ordering | Little endian                                             |

The PWM block contains a variable number of 12-bit PWMs. The number of PWMs is configurable via `PWM_PORT_CNT` and must be even.

Depending on PWM count, there will be (`PWM_PORT_CNT`/2) number of 32-bit configuration registers, each register contains a duty cycle configuration of two PWM outputs (called LO and HI) The structure of the register follows:

| Bits | Access | Content | 
| ---- | ------ | ------- |
| 31-28 | - | - |
| 27-16 | R/W | PWM HI duty cycle |
| 15-12 | - |  - |
| 11-0 | R/W | PWM LO duty cycle |

The registers are mapped to addresses in sequential manner. For example, if `PWM_PORT_CNT` is 8, there will be 4 registers available at these addresses:

- `32'hxxxx_xxx0`
- `32'hxxxx_xxx4`
- `32'hxxxx_xxx8`
- `32'hxxxx_xxxC`

where 'x' means don't care -- this part of address will be mapped by your interconnect.

## Debouncer
The debouncer block is useful for denoising external user inputs, such as buttons (often present on learning FPGA boards, such as Basys 3, Zybo, Nexys Video...).

The debouncer contains variable number of outputs (configurable by `PORT_CNT` parameter, up to 32). The width of debouncing timer is configurable (`TIMER_WIDTH`). It is recommended to configure this parameter depending on clock speed.

The debouncer works as following: if change on input is detected, a timer will be started. If timer reaches top (see note), input will be passed to output. However, if a change is detected before timer reaches top, the timer will be restarted and the process is repeated.

*Note: to spare some logic, only top bit of the timer is checked. As such, the real length of timer is roughly one bit lower.*

`TIMER_WIDTH` should be calculated as following:

`TIMER_WIDTH` = ceil(log2(largest_gap_between_bounces * clock_speed)) + 1

The default value (22) is calculated for 100 MHz clock and ~20 ms gap between bounces.

| Parameter              | Value                                                     |
|------------------------|-----------------------------------------------------------|
| Wishbone revision      | B4                                                        |
| Interface type         | SLAVE                                                     |
| Supported cycles       | SLAVE, (pipelined) READ/WRITE                             |
| Data port size         | 32 bit                                                    |
| Data port granularity  | 32 bit (byte or half word access not supported)           |
| Data port max size     | 32 bit                                                    |
| Data transfer ordering | Little endian                                             |

There is only one read-only register, where each bit represents a single input. It there is less than 32 inputs configured, bits will be mapped LSB-first, the others will be read-only zero.