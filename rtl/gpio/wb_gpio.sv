module wb_gpio(
    wishbone_p_if.slave     wb,
    inout wire logic [31:0] gpio_ports
);

    // Don't forget about little endian ordering!
    typedef struct packed {
        logic [31:0] reserved;
        logic [31:0] rd_val;
        logic [31:0] wr_val;
        logic [31:0] dir;     // Item 0
    } gpio_registers;

    gpio_registers          regs;
    // This has to be strictly a wire. If not, it could happen it is placed inside some always block
    // and then, if used in another block, it would depend on block execution order.
    wire logic      [1:0]   reg_select;
    logic           [31:0]  gpio_ports_sync;
    
    /////////////////////////////////////////////////
    // Wishbone handling
    /////////////////////////////////////////////////
    // Convenience wire.
    assign reg_select = wb.adr[3:2];

    always_comb begin : wishbone_signal_handling
        // This is a simple register set; we can keep
        // with whatever master's pace is.
        wb.stall   = 1'b0;

        // ACK signal may be synchronous (registered) or asynchronous
        // depending on requirements for critical path and delay.
        // This is valid for both non-pipelined and pipelined
        // Wishbone classic interfaces.
        wb.ack     = wb.cyc && wb.stb;
    end

    always_comb begin : register_read_proc
        if (wb.cyc && wb.stb && !wb.we) begin
            wb.dat_o = regs[reg_select * 32 +: 32];
        end else begin
            wb.dat_o = 32'h0;
        end
    end 

    always_ff @(posedge wb.clk_i) begin : register_write_proc
        if (wb.rst_i) begin
            // Default direction of GPIOs should be "input".
            // Reason: If there is a bad intitial write value,
            // it could cause a short.
            regs.dir       <= 32'h0;
            regs.wr_val    <= 32'h0;
            regs.reserved  <= 32'h0;
        end else if (wb.cyc && wb.stb && wb.we) begin
            case (reg_select)
                2'b00: regs.dir    <= wb.dat_i;
                2'b01: regs.wr_val <= wb.dat_i;
                default: begin end
            endcase    
        end
    end

    /////////////////////////////////////////////////
    // IO machinery
    /////////////////////////////////////////////////
    always_ff @(posedge wb.clk_i) begin : input_ff_proc
        regs.rd_val <= gpio_ports_sync;
    end

    // Input data need to be synchronized with the system's
    // clock domain.
    generic_synchronizer #(
        .LEN(32),
        .STAGES(2)
    ) sync (
        .clk(wb.clk_i),
        .en(1'b1),
        .data_in(gpio_ports),
        .data_out(gpio_ports_sync),
        .rise(),
        .fall()
    );

    // This description can be used to infer IOBUF correctly
    // in Xilinx's tools (and I hope in many others as well).
    // It is better than using proprietary block explicitly (in terms of portability).
    generate
        genvar i;
        for (i = 0; i < 32; i++) begin
            // 1 -> output
            // 0 -> input
            assign gpio_ports[i] = regs.dir[i] ? regs.wr_val[i] : 1'bz;
        end
    endgenerate
endmodule