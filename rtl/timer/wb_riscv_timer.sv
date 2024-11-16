`default_nettype none

/*
RISC-V Machine-Level compliant timer.

Address is only partially decoded as following:
bits | meaning
4-3  | register select
2    | high/low word select
1-0  | not used (only word-wide granularity supported)
*/
module wb_riscv_timer #(
    parameter [63:0] CLK_FREQUENCY_HZ
) (
    wishbone_p_if.slave wb,
    output logic        irq
);
    
    logic      [63:0] mtime_reg;
    logic             mtime_we;
    logic      [63:0] mtimecmp_reg;
    logic             mtimecmp_we;

    // Which register is selected.
    wire logic [1:0]  reg_select;
    // 0 -> lower 32 bits, 1 -> top 32 bits.
    wire logic        high_word;

    /////////////////////////////////////////////////
    // Timer machinery
    /////////////////////////////////////////////////
    always_ff @( posedge wb.clk_i ) begin : timer_proc
        if (wb.rst_i) begin
            mtime_reg <= 64'h0;
        // CPU access.
        end else if (mtime_we) begin
            mtime_reg[high_word * 32 +: 32] <= wb.dat_i;
        end else begin
            mtime_reg <= mtime_reg + 1;
        end
    end

    always_ff @( posedge wb.clk_i ) begin : timer_cmp_proc
        if (wb.rst_i) begin
            mtimecmp_reg <= 64'h0;
        // CPU access.
        end else if (mtimecmp_we) begin
            mtimecmp_reg[high_word * 32 +: 32] <= wb.dat_i;
        end
    end

    /////////////////////////////////////////////////
    // Interrupt handling
    /////////////////////////////////////////////////
    always_comb begin : irq_proc
        if (mtime_reg >= mtimecmp_reg) begin
            irq = 1'b1;
        end else begin
            irq = 1'b0;
        end
    end

    /////////////////////////////////////////////////
    // Wishbone handling
    /////////////////////////////////////////////////
    // Convenience wire.
    assign reg_select = wb.adr[4:3];
    assign high_word  = wb.adr[2];

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
            case (reg_select)
                2'b00: begin
                    wb.dat_o = mtime_reg[high_word * 32 +: 32];
                end
                2'b01: begin
                    wb.dat_o = mtimecmp_reg[high_word * 32 +: 32];
                end
                default: begin
                    wb.dat_o = CLK_FREQUENCY_HZ[high_word * 32 +: 32];
                end
            endcase
        end else begin
            wb.dat_o = 32'h0;
        end
    end 

    assign mtime_we    = wb.cyc && wb.stb && wb.we && reg_select == 2'b00;
    assign mtimecmp_we = wb.cyc && wb.stb && wb.we && reg_select == 2'b01;

endmodule