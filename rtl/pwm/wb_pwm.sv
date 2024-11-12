`default_nettype none

module wb_pwm #(
    parameter PWM_PORT_CNT = 8
) (
    wishbone_p_if.slave                 wb,
    output logic [PWM_PORT_CNT-1:0]     pwm_out_ports
);
    localparam PWM_REG_COUNT = PWM_PORT_CNT / 2;

    typedef struct packed {
        logic [3:0 ] reserved_2;
        logic [11:0] pwm_hi;
        logic [3:0 ] reserved_1;
        logic [11:0] pwm_lo;
    } pwm_register;

    pwm_register                              regs[PWM_REG_COUNT];
    wire logic  [$clog2(PWM_REG_COUNT) - 1:0] reg_select;
    logic       [11:0]                        timer_val;
    logic                                     timer_zero;

    /////////////////////////////////////////////////
    // PWM timer and comparators
    /////////////////////////////////////////////////
    assign timer_zero = timer_val == 16'b0;

    always_ff @( posedge wb.clk_i ) begin : timer_proc
        if (wb.rst_i) begin
            timer_val <= 16'h0;
        end else begin
            timer_val <= timer_val + 1;
        end
    end

    always_ff @( posedge wb.clk_i ) begin : pwm_proc

        for (int i = 0; i < PWM_REG_COUNT; i++) begin
            if (timer_val == regs[i].pwm_lo) begin
                pwm_out_ports[i * 2] <= 1'b0;
            end else if (timer_val == 16'h0) begin
                pwm_out_ports[i * 2] <= 1'b1;
            end

            if (timer_val == regs[i].pwm_hi) begin
                pwm_out_ports[(i * 2) + 1] <= 1'b0;
            end else if (timer_val == 16'h0) begin
                pwm_out_ports[(i * 2) + 1] <= 1'b1;
            end
        end
    end

    /////////////////////////////////////////////////
    // Wishbone handling
    /////////////////////////////////////////////////
    // Convenience wire.
    assign reg_select = wb.adr[$clog2(PWM_REG_COUNT) + 1:2];

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
            wb.dat_o = regs[reg_select];
        end else begin
            wb.dat_o = 32'h0;
        end
    end 

    always_ff @(posedge wb.clk_i) begin : register_write_proc
        if (wb.rst_i) begin
            for (int i = 0; i < PWM_REG_COUNT; i++) begin
                regs[i] <= 32'h0;
            end
        end else if (wb.cyc && wb.stb && wb.we) begin
            regs[reg_select] <= wb.dat_i;
        end
    end

    /////////////////////////////////////////////////
    // Param checks
    /////////////////////////////////////////////////
    initial begin
        assert (PWM_PORT_CNT > 1) 
        else   $fatal(1, "PWM_PORT_CNT must be >1!");

        assert (PWM_PORT_CNT % 2 == 0) 
        else   $fatal(1, "PWM_PORT_CNT must be even!");
    end
endmodule