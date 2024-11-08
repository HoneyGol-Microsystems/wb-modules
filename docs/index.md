# VESP Wishbone Modules documentation
Welcome to the VESP Wishbone Modules documentation. Here you can find information about individual modules, debugging methods and generic information about Wishbone compatibility.

## Wishbone compatibility

Modules are written to be compatible with the Wishbone B4 specification. Some modules support classic non-pipelined, some support pipelined or both. Some modules may support only single transaction cycles. Refer to a documentation of every module.

## Signal naming
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
| stall       | STALL_O             |
