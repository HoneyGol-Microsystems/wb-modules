module wb_xpm_ram_pipelined #(
    parameter ADDR_WIDTH = 20,
    parameter DATA_WIDTH = 32,
    parameter LATENCY    = 2,
    parameter INIT_FILE  = "none",
    parameter WORD_COUNT = 64
) (
    wishbone_p_if.slave   wb
);
    localparam                  a_pad_bits = $clog2(DATA_WIDTH/8);
    logic [ADDR_WIDTH-1:0]      a_padded;
    logic                       memory_enable;
    logic [(DATA_WIDTH/8)-1:0]  we_per_byte;
    logic [0:0]                 ram_latency_counter;

    //////////////////////////////////////////////////////
    // Wishbone controller
    //////////////////////////////////////////////////////

    always_ff @( posedge wb.clk_i ) begin : operation_start
        if (wb.rst_i | ~wb.cyc) begin // Reset or unset cyc clears all pending operations.
            ram_latency_counter     <= 1'b0;
        end if (wb.cyc) begin       // Operations are valid iff cyc is set.
            ram_latency_counter     <= (ram_latency_counter << 1) | (wb.stb);
        end
    end

    always_comb begin : output_handling
        wb.ack = 1'b0;

        if (ram_latency_counter[$size(ram_latency_counter)-1]) begin
            wb.ack = 1'b1;
        end
    end

    always_comb begin : memory_control
        memory_enable = wb.cyc & wb.stb;
    end

    always_comb begin : wishbone_signal_handling
        // This is a simple pipelined peripheral; we can keep
        // with whatever master's pace is.
        wb.stall   = 1'b0;
    end

    //////////////////////////////////////////////////////
    // RAM Datapath
    //////////////////////////////////////////////////////

    // xpm_memory_spram: Single Port RAM
    // Xilinx Parameterized Macro, version 2024.1
    xpm_memory_spram #(
        .ADDR_WIDTH_A(ADDR_WIDTH),
        .BYTE_WRITE_WIDTH_A(8), // To enable writing per byte, thus masking.
        .MEMORY_INIT_FILE(INIT_FILE),
        .MEMORY_INIT_PARAM(""),
        .MEMORY_OPTIMIZATION("false"),
        .MEMORY_PRIMITIVE("block"),
        .MEMORY_SIZE(WORD_COUNT * DATA_WIDTH),
        .READ_DATA_WIDTH_A(DATA_WIDTH),
        .READ_LATENCY_A(1),
        .SIM_ASSERT_CHK(1),
        .USE_MEM_INIT_MMI(1),
        .WRITE_DATA_WIDTH_A(DATA_WIDTH),
        .WRITE_MODE_A("write_first")
    )
    xpm_memory_spram_inst (
        .douta(wb.dat_o),
        .addra(a_padded),
        .clka(wb.clk_i),
        .dina(wb.dat_i),
        .ena(memory_enable),
        .rsta(wb.rst_i),
        .wea(we_per_byte) // Vector (for every byte), not a single bit!
    );
    // End of xpm_memory_spram_inst instantiation

    // Address needs to be padded, because XPM is addressed by words, whereas PC 
    // contains address by bytes.
    assign a_padded    = {{a_pad_bits{1'b0}}, wb.adr[ADDR_WIDTH-1:a_pad_bits]};

    // Create write enable signal extended to all bytes in word
    // by mask (sel).
    assign we_per_byte = {(DATA_WIDTH/8){wb.we}} & wb.sel;

endmodule