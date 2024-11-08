`default_nettype none

module gpio_tb ();
    
    import tb_pkg::wb_p_sim_master;

    logic             clk, rst;
    wire logic [31:0] gpio_ports;
    logic      [31:0] port_drive; // Workaround to be able to drive net from initial block.

    wishbone_p_if wb_if(
        .clk_i(clk),
        .rst_i(rst)
    );
    wb_gpio dut(
        .wb(wb_if.slave),
        .gpio_ports(gpio_ports)
    );
    wb_p_sim_master dut_if;

    initial begin
        logic [31:0] rand_addr;
        logic [31:0] rand_data;
        logic [31:0] dut_read_data;
        logic [31:0] rand_dirs;
        logic [31:0] rand_output;

        `ifdef QUESTA
            $wlfdumpvars();
        `else
            $dumpvars;
        `endif

        dut_if     = new(wb_if.master);
        port_drive = 32'hzzzz_zzzz;

        rst <= 1'b1;
        #10;
        rst <= 1'b0;
        #2;

        // Write random data to a random register.
        for (int i = 0; i < 32; i++) begin
            rand_addr = $urandom_range(0, 1) << 2;
            rand_data = $urandom();

            dut_if.single_write(rand_addr, 4'b1111, rand_data);
            dut_if.single_read(rand_addr, 4'b1111, dut_read_data);

            assert (rand_data == dut_read_data)
            else   $error("DUT read/write error! A: %d Written to DUT: 'h%h Read from DUT: 'h%h", rand_addr, rand_data, dut_read_data);
        end

        // Output test. Set random ports to output and send random data.
        for (int i = 0; i < 32; i++) begin
            rand_dirs   = $urandom();
            rand_output = $urandom();
            dut_if.single_write(32'b0000, 4'b1111, rand_dirs);
            dut_if.single_write(32'b0100, 4'b1111, rand_output);
            
            for (int i = 0; i < 32; i++) begin
                // Output mode. Expected value written to WR reg.
                if (rand_dirs[i] == 1'b1) begin
                    assert(gpio_ports[i] === rand_output[i])
                    else  $error("GPIO ports output error! Bit %0d should be 1'b%0b, is 1'b%0b!", i, rand_output[i], gpio_ports[i]);
                    break;                    
                // Input mode. Expected Z.
                end else begin
                    assert(gpio_ports[i] === 1'bz)
                    else  $error("GPIO ports output error! Bit %0d should be 1'bz (input mode), is 1'b%0b!", i, gpio_ports[i]);
                    break;
                end
            end
        end

        // Input test.
        for (int i = 0; i < 32; i++) begin
            dut_if.single_write(32'b0000, 4'b1111, 32'h0); // Set all ports to input.
            rand_data   = $urandom();
            port_drive  = rand_data;

            // Wait for value to pass through the synchronizer.
            #10;
            dut_if.single_read(32'b1000, 4'b1111, dut_read_data);
            assert (dut_read_data === rand_data) 
            else   $error("GPIO ports input error. Written to ports: 'h%h Read from regs: 'h%h", rand_data, dut_read_data);
        end

        #10;
        $finish;
    end

    assign gpio_ports = port_drive;

    always begin
        clk <= 1'b0;
        #1;
        clk <= 1'b1;
        #1;
    end

endmodule