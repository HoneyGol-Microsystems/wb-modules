`default_nettype none

module riscv_timer_tb ();
    
    import tb_pkg::wb_p_sim_master;
    
    // A random 64-bit wide number to pass as freq param to timer.
    // localparam CLK_FREQ_VAL = 64'hdead_beef_cafe_aaaa;
    localparam CLK_FREQ_VAL = 64'hdead_beef_cafe_aaaa;

    logic clk, rst;
    logic irq_timer;

    wishbone_p_if wb_if(
        .clk_i(clk),
        .rst_i(rst)
    );
    wb_riscv_timer #(
        .CLK_FREQUENCY_HZ(CLK_FREQ_VAL)
    ) dut(
        .wb(wb_if.slave),
        .irq(irq_timer)
    );
    wb_p_sim_master dut_if;

    initial begin

        logic [31:0] dut_read_lo;
        logic [31:0] dut_read_hi;
        logic [63:0] timer_old_value;

        logic [31:0] mtimecmp_rand_hi;
        logic [31:0] mtimecmp_rand_lo;
        logic [31:0] mtime_rand_hi;
        logic [31:0] mtime_rand_lo;

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

        // Test whether tick freq is readable.
        dut_if.single_read(5'b10000, 4'b1111, dut_read_lo);
        dut_if.single_read(5'b10100, 4'b1111, dut_read_hi);

        assert ({dut_read_hi, dut_read_lo} == CLK_FREQ_VAL) 
        else   $error("Timer tick mismatch! Expected: 'h%16h, read: 'h%16h", CLK_FREQ_VAL, {dut_read_hi, dut_read_lo});

        // Test whether mtime is readable and increments.
        // Because the timer is 64-bit, we don't have to check for overflow yet.
        for (int i = 0; i < 100; i++) begin
            dut_if.single_read(5'b00000, 4'b1111, dut_read_lo);
            dut_if.single_read(5'b00100, 4'b1111, dut_read_hi);
            timer_old_value = {dut_read_hi, dut_read_lo};

            dut_if.single_read(5'b00000, 4'b1111, dut_read_lo);
            dut_if.single_read(5'b00100, 4'b1111, dut_read_hi);
            assert (timer_old_value < {dut_read_hi, dut_read_lo}) 
            else   $error("Timer does not increment correctly!");

            // Wait a random # of cycles up to 10000 * 2 (aligned to 2). 
            #($urandom_range(0, 10000) << 1);
        end

        // Test whether mtime is writable.
        dut_if.single_write(5'b00000, 4'b1111, 32'h0);
        dut_if.single_write(5'b00100, 4'b1111, 32'h0);
        dut_if.single_read(5'b00000, 4'b1111, dut_read_lo);
        dut_if.single_read(5'b00100, 4'b1111, dut_read_hi);
        // Reads should take max 2 cycles, hence 2 cycle tolerance.
        assert ({dut_read_hi, dut_read_lo} <= 2) 
        else   $error("mtime write error!");

        // Test whether mtimecmp is writable.
        mtimecmp_rand_lo = $urandom_range(0, (2**32) - 1);
        mtimecmp_rand_hi = $urandom_range(0, (2**32) - 1);
        dut_if.single_write(5'b01000, 4'b1111, mtimecmp_rand_lo);
        dut_if.single_write(5'b01100, 4'b1111, mtimecmp_rand_hi);
        dut_if.single_read(5'b01000, 4'b1111, dut_read_lo);
        dut_if.single_read(5'b01100, 4'b1111, dut_read_hi);
        
        assert ({dut_read_hi, dut_read_lo} === {mtimecmp_rand_hi, mtimecmp_rand_lo}) 
        else   $error("mtimecmp write error!");

        // Set mtimecmp and wait for IRQ trigger.
        dut_if.single_write(5'b01000, 4'b1111, 'hffff);
        dut_if.single_write(5'b01100, 4'b1111, 'h0);
        assert (irq_timer === 1'b0) 
        else   $error("IRQ incorrectly triggered!");
        #('hffff * 2); // Approximation
        assert (irq_timer === 1'b1) 
        else   $error("IRQ not triggered!");
        // Try to disable IRQ by writing a higher value to mtimecmp.
        dut_if.single_write(5'b01000, 4'b1111, 'hfffff);
        assert (irq_timer === 1'b0) 
        else   $error("IRQ incorrectly triggered!");

        // Write random values to mtime and mtimecmp and check for IRQ trigger.
        for (int i = 0; i < 1000; i++) begin
            mtimecmp_rand_lo = $urandom_range(0, (2**32) - 1);
            mtimecmp_rand_hi = $urandom_range(0, (2**32) - 10); // A little time reserve to make sure timer won't overflow to zero (so we can subtract safely in comparison).
            mtime_rand_lo    = $urandom_range(0, (2**32) - 1);
            mtime_rand_lo    = $urandom_range(0, (2**32) - 1);

            dut_if.single_write(5'b01000, 4'b1111, mtimecmp_rand_lo);
            dut_if.single_write(5'b01100, 4'b1111, mtimecmp_rand_hi);
            dut_if.single_write(5'b00000, 4'b1111, mtime_rand_lo);
            dut_if.single_write(5'b00100, 4'b1111, mtime_rand_hi);

            // Writes takes 2 cycles, so add this to the comparison.
            if ({mtime_rand_hi, mtime_rand_lo} + 2 >= {mtimecmp_rand_hi, mtimecmp_rand_lo}) begin
                assert (irq_timer) 
                else   $error("IRQ not triggered!");
            end else begin
                assert (!irq_timer)
                else   $error("IRQ incorrectly triggered!");
            end
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