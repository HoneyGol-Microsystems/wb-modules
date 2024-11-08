module wb_xpm_ram #(
    parameter ADDR_WIDTH = 20,
    parameter DATA_WIDTH = 32,
    parameter LATENCY    = 2,
    parameter INIT_FILE  = "none",
    parameter WORD_COUNT = 64
) (
    wishbone_if.slave   wb
);
    typedef enum { 
        ST_IDLE,
        ST_WAIT
    } STATES;

    STATES current_state, next_state;

    logic                       counter_top;
    logic                       memory_enable;
    logic [$clog2(LATENCY)-1:0] counter_val;
    logic [(DATA_WIDTH/8)-1:0]  we_per_byte;

    localparam             a_pad_bits = $clog2(DATA_WIDTH/8);
    logic [ADDR_WIDTH-1:0] a_padded;

    //////////////////////////////////////////
    // Controller -- STM
    //////////////////////////////////////////
    always_comb begin : output_proc

        memory_enable   = 1'b0;
        wb.ack          = 1'b0;

        unique case (current_state)
            ST_IDLE: begin
                if (wb.cyc && wb.stb) begin
                    memory_enable = 1'b1;
                end
            end

            ST_WAIT: begin
                if (counter_top) begin
                    wb.ack = 1'b1;
                    memory_enable = 1'b1;
                end else if (wb.cyc && wb.stb) begin
                    memory_enable = 1'b1;
                end
            end
        endcase
    end

    always_comb begin : next_state_proc
        
        next_state = current_state;

        unique case (current_state)
            ST_IDLE: begin
                if (wb.cyc && wb.stb) begin
                    next_state = ST_WAIT;
                end
            end 
            
            ST_WAIT: begin
                if (counter_top) begin
                    next_state = ST_IDLE;
                end else if (wb.cyc && wb.stb) begin
                    next_state = ST_WAIT;
                end else begin
                    next_state = ST_IDLE;
                end
            end
        endcase
    end

    always_ff @( posedge wb.clk_i ) begin : ff_proc
        if (wb.rst_i) begin
            current_state <= ST_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_ff @( posedge wb.clk_i ) begin : counter_proc
        if (wb.rst_i) begin
            counter_val <= 'h0;
        end else if (memory_enable) begin
            counter_val <= counter_val + 'h1;
        end else begin
            counter_val <= 'h0;
        end
    end

    assign counter_top = counter_val == LATENCY - 1;
    
    //////////////////////////////////////////////////////
    // Datapath
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