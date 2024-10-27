// !!! This is a very basic testbench for only default parameters.
module xpm_ram_tb ();
    
    import tb_pkg::wb_sim_master;
    import tb_pkg::xpm_ram_model;

    logic clk, rst;
    wishbone_if wb_if(
        .clk_i(clk),
        .rst_i(rst)
    );
    xpm_ram dut(wb_if.slave);
    wb_sim_master dut_if;
    xpm_ram_model model;

    initial begin
        logic [19:0] rand_addr;
        logic [31:0] rand_data;
        logic [3:0]  rand_mask;
        logic [31:0] model_read_data;
        logic [31:0] dut_read_data;

        `ifdef QUESTA
            $wlfdumpvars();
        `else
            $dumpvars;
        `endif

        dut_if = new(wb_if.master);
        model  = new();

        rst <= 1'b1;
        #10;
        rst <= 1'b0;
        #2;

        // Write randomly masked random data to a random address.
        for (int i = 0; i < 64; i++) begin
            rand_addr = $urandom_range(0, 63 * 4) & ~('b11);
            rand_data = $urandom();
            rand_mask = $urandom_range(4'b0000, 4'b1111);

            // PWA = per word address, to debug XPM, which is addressed by words.
            $display("WRITE 'h%h to %d (PWA: %d)", rand_data & { {8{rand_mask[3]}}, {8{rand_mask[2]}}, {8{rand_mask[1]}}, {8{rand_mask[0]}} }, rand_addr, rand_addr / 4);
            model.write(rand_addr, rand_mask, rand_data);
            dut_if.single_write(rand_addr, rand_mask, rand_data);
        end

        // Verify contents of both memories are the same.
        for (int i = 0; i < 63 * 4; i += 4) begin
            
            model_read_data = model.read(i, 4'b1111);
            dut_if.single_read(i, 4'b1111, dut_read_data);

            assert (model_read_data == dut_read_data) 
            else   $error("Model read data differs from DUT! A: %d PWA: %d Model: 'h%h DUT: 'h%h", i, i/4, model_read_data, dut_read_data);
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