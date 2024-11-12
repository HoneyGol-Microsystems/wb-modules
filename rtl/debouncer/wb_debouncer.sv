`default_nettype none

module wb_debouncer #(
    parameter PORT_CNT      = 8,
    parameter TIMER_WIDTH   = 22
) (
    wishbone_p_if.slave              wb,
    input wire logic [PORT_CNT-1:0]  input_ports
);
    logic [PORT_CNT-1:0] debounced;
    logic [31:0]         debounced_reg;
    
    /////////////////////////////////////////////////
    // Debouncer instantiation
    /////////////////////////////////////////////////
    generate
        genvar i;
        for (i = 0; i < PORT_CNT; i++) begin
            debouncer_block #(
                .TIMER_WIDTH(TIMER_WIDTH)
            ) debouncer (
                .clk(wb.clk_i),
                .rst(wb.rst_i),
                .in(input_ports[i]),
                .out(debounced[i])
            );
        end
    endgenerate

    /////////////////////////////////////////////////
    // Wishbone handling
    /////////////////////////////////////////////////
    assign debounced_reg = { {(32-PORT_CNT){1'b0}}, debounced };

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
            wb.dat_o = debounced_reg;
        end else begin
            wb.dat_o = 32'h0;
        end
    end 

    /////////////////////////////////////////////////
    // Param checks
    /////////////////////////////////////////////////
    initial begin
        assert (PORT_CNT > 0 && PORT_CNT <= 32) 
        else   $fatal(1, "PORT_CNT must be within [1, 32]!");
    end
endmodule