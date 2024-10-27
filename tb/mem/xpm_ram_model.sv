class xpm_ram_model #(
    parameter ADDR_WIDTH = 20,
    parameter DATA_WIDTH = 32,
    parameter WORD_COUNT = 64
);

    bit [DATA_WIDTH-1:0] mem [WORD_COUNT-1:0];

    function new();
        
    endfunction //new()

    function bit[DATA_WIDTH-1:0] expand_mask(
        input bit [(DATA_WIDTH/8)-1:0]   mask
    );
        bit [DATA_WIDTH-1:0] expanded_mask;

        for (int i = 0; i < DATA_WIDTH / 8; i++) begin
            expanded_mask[i * 8 +: 8] = {8{mask[i]}};
        end

        return expanded_mask;
    endfunction // expand_mask

    function bit[DATA_WIDTH-1:0] read(
        input  bit [ADDR_WIDTH-1:0]       addr,
        input  bit [(DATA_WIDTH/8)-1:0]   mask
    );
        return mem[addr] & expand_mask(mask);
    endfunction // read

    function void write(
        input  bit   [ADDR_WIDTH-1:0]       addr,
        input  bit   [(DATA_WIDTH/8)-1:0]   mask,
        input  logic [DATA_WIDTH-1:0]       write_data
    );
        for (int i = 0; i < DATA_WIDTH / 8; i++) begin
            if (mask[i]) begin
                mem[addr][i * 8 +: 8] = write_data[i * 8 +: 8];
            end
        end
    endfunction // write

endclass //xpm_ram_model