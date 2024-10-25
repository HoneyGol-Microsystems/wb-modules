interface wishbone_if #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32,
    parameter GRANULARITY = 8
) (
    input logic clk_i,
    input logic rst_i
);

    logic [ADDR_WIDTH-1:0]             adr;
    logic [DATA_WIDTH-1:0]             dat_to_master;
    logic [DATA_WIDTH-1:0]             dat_from_master;
    logic                              we;
    logic [DATA_WIDTH/GRANULARITY-1:0] sel;
    logic                              stb;
    logic                              ack;
    logic                              cyc;

    modport master (
        input   .dat_i(dat_to_master),
        input   ack,
        output  adr,
        output  .dat_o(dat_from_master),
        output  we,
        output  sel,
        output  stb,
        output  cyc
    );

    modport slave (
        input   adr,
        input   .dat_i(dat_from_master),
        input   we,
        input   sel,
        input   stb,
        input   cyc,
        output  .dat_o(dat_to_master),
        output  ack
    );

    initial begin
        assert (GRANULARITY == 8 || GRANULARITY == 16 || GRANULARITY == 32) 
        else   $fatal("Invalid granularity! (Allowed values are: 8, 16, 32).");
    end

endinterface // wishbone_if