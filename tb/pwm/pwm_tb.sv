`default_nettype none

module pwm_tb ();
    
    localparam PWM_TIMER_SIZE = 2**12;
    localparam MEAS_TOLERANCE = 40; // ~1 % error.

    import tb_pkg::wb_p_sim_master;

    logic             clk, rst;
    wire logic [7:0]  pwm_out_ports;

    wishbone_p_if wb_if(
        .clk_i(clk),
        .rst_i(rst)
    );
    wb_pwm dut(
        .wb(wb_if.slave),
        .pwm_out_ports(pwm_out_ports)
    );
    wb_p_sim_master dut_if;

    task automatic meas_duty_cycle(input int port_index, output int measured_ones);
        measured_ones = 0;
        for (int i = 0; i < PWM_TIMER_SIZE; i++) begin
            if (pwm_out_ports[port_index] == 1'b1) begin
                measured_ones++;
            end
            @(posedge clk);
        end
    endtask

    function bit comp_tolerance(input int val, input int target, input int tolerance);
        return (val > target - tolerance) && (val < target + tolerance);
    endfunction

    initial begin
        int          measured_ones;
        int          pwm_reg_lo;
        int          pwm_val_lo;
        int          pwm_reg_hi;
        int          pwm_val_hi;
        logic [31:0] rand_addr;
        logic [31:0] rand_data;
        logic [31:0] dut_read_data;

        `ifdef QUESTA
            $wlfdumpvars();
        `else
            $dumpvars;
        `endif

        dut_if     = new(wb_if.master);

        rst <= 1'b1;
        #10;
        rst <= 1'b0;
        #2;

        // Write random data to a random register.
        for (int i = 0; i < 32; i++) begin
            rand_addr = $urandom_range(0, 3) << 2;
            rand_data = $urandom();

            dut_if.single_write(rand_addr, 4'b1111, rand_data);
            dut_if.single_read(rand_addr, 4'b1111, dut_read_data);
            assert (rand_data == dut_read_data) 
            else   $error("DUT reg write/read mismatch. Expected: 'h%h, got: 'h%h", rand_data, dut_read_data);
        end

        // Write random duty cycle to a random PWM register and measure.
        for (int i = 0; i < 128; i++) begin
            rand_addr  = $urandom_range(0, 3) << 2;
            rand_data  = $urandom();
            pwm_reg_lo = (rand_addr >> 2) * 2; // Index of PWM port altered by address.
            pwm_val_lo = rand_data & 'h0000_0FFF;
            pwm_reg_hi = ((rand_addr >> 2) * 2) + 1; // Index of PWM port altered by address.
            pwm_val_hi = (rand_data & 'h0FFF_0000) >> 16;

            dut_if.single_write(
                rand_addr, 
                4'b1111,
                rand_data);
            
            // Synchronize and compare with defined tolerance.
            #(PWM_TIMER_SIZE * 2);
            meas_duty_cycle(pwm_reg_lo, measured_ones);
            assert (comp_tolerance(pwm_val_lo, measured_ones, MEAS_TOLERANCE))
            else   $error("PWM duty cycle error. Written: %d Measured: %d", pwm_val_lo, measured_ones);

            meas_duty_cycle(pwm_reg_hi, measured_ones); 
            assert (comp_tolerance(pwm_val_hi, measured_ones, MEAS_TOLERANCE))
            else   $error("PWM duty cycle error. Written: %d Measured: %d", pwm_val_hi, measured_ones);
        end

        #10;
        $finish;
    end

    always begin
        clk <= 1'b0;
        #1;
        clk <= 1'b1;
        #1;
    end

endmodule