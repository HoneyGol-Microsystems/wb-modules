module xpm_ram_tb ();
    
    logic clk, rst;
    wishbone_if wb_if(
        .clk_i(clk),
        .rst_i(rst)
    );
    xpm_ram dut(wb_if.slave);
    wb_sim_master m;

    initial begin
        logic [31:0] read_data;

        rst <= 1'b1;
        #10;
        rst <= 1'b0;
        #2;

        m = new(wb_if.master);
        m.single_read(20'h0, 4'b1111, read_data);
        $display("Data read from address 0: %d", read_data);

        $finish;
    end

    always begin
        clk <= 1'b0;
        #1;
        clk <= 1'b1;
        #1;
    end

endmodule