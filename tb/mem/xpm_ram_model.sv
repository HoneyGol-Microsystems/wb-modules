class xpm_ram_model #(
    parameter ADDR_WIDTH  = 20,
    parameter DATA_WIDTH  = 32,
    parameter GRANULARITY = 8,
    parameter WORD_COUNT  = 64
);

    // Granules per word. Usually GRANULARITY = 8, which makes this value equal
    // to bytes per word.
    localparam GRAN_PER_WORD = DATA_WIDTH/GRANULARITY;

    bit [GRANULARITY-1:0] mem [(WORD_COUNT * GRAN_PER_WORD)-1:0];

    function new();
        
    endfunction //new()

    // function bit[DATA_WIDTH-1:0] expand_mask(
    //     input bit [(DATA_WIDTH/GRANULARITY)-1:0]   mask
    // );
    //     bit [DATA_WIDTH-1:0] expanded_mask;

    //     for (int i = 0; i < DATA_WIDTH / GRANULARITY; i++) begin
    //         expanded_mask[i * GRANULARITY +: GRANULARITY] = {GRANULARITY{mask[i]}};
    //     end

    //     return expanded_mask;
    // endfunction // expand_mask

    function bit[DATA_WIDTH-1:0] read(
        input  bit [ADDR_WIDTH-1:0]       addr,
        input  bit [GRAN_PER_WORD-1:0]   mask
    );

        bit [DATA_WIDTH-1:0] read_data = 32'h0;

        for (int i = 0; i < GRAN_PER_WORD; i++) begin
            if (mask[i]) begin
                read_data[i * GRANULARITY +: GRANULARITY] = mem[addr + i];
            end
        end
        
        return read_data;

    endfunction // read

    function void write(
        input  bit   [ADDR_WIDTH-1:0]       addr,
        input  bit   [GRAN_PER_WORD-1:0]   mask,
        input  logic [DATA_WIDTH-1:0]       write_data
    );
        for (int i = 0; i < GRAN_PER_WORD; i++) begin
            if (mask[i]) begin
                mem[addr + i] = write_data[i * GRANULARITY +: GRANULARITY];
            end
        end
    endfunction // write

endclass //xpm_ram_model