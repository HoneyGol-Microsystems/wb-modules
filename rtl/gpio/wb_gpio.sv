module wb_gpio(
    wishbone_p_if.slave     wb
    inout wire logic [31:0] gpio_ports
);
    typedef struct packed {
        logic [31:0] dir;
        logic [31:0] wr_val;
        logic [31:0] rd_val;
        logic [31:0] reserved;
    } gpio_registers;

    gpio_registers regs;
    logic          reg_select;
    logic          gpio_ports_sync;
    
    /////////////////////////////////////////////////
    // Wishbone handling
    /////////////////////////////////////////////////
    always_comb begin : wishbone_signal_handling

        // Convenience wire.
        reg_select = wb.adr[3:2];

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
            dat_o = regs[reg_select * 32 :+ 32]
        end else begin
            dat_o = 32'h0;
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
                2'b10: regs.rd_val <= wb.dat_i;
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
            assign gpio_ports[i] = regs.dir[i] ? regs.wr[i] : 1'bZ;
        end
    endgenerate
endmodule