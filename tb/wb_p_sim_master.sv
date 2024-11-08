class wb_p_sim_master #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32,
    parameter GRANULARITY = 8
);
    
    virtual wishbone_p_if.master wb_if;

    function new(virtual wishbone_p_if.master wb_if);
        this.wb_if = wb_if;
    endfunction

    task single_read(
        input  logic [ADDR_WIDTH-1:0]       addr,
        input  logic [(DATA_WIDTH/8)-1:0]   mask,
        output logic [DATA_WIDTH-1:0]       read_data
    );
        this.wb_if.adr <= addr;
        this.wb_if.we  <= 1'b0;
        this.wb_if.sel <= mask;
        this.wb_if.stb <= 1'b1;
        this.wb_if.cyc <= 1'b1;

        fork
            begin
                // Pipelined -> strobe is deasserted immediately.
                @(posedge wb_if.clk_i);
                this.wb_if.stb <= 1'b0;
            end

            begin
                // We wait for ack (which will be only one).
                @(posedge wb_if.ack);
                read_data = this.wb_if.dat_i;
            end
        join
        
        this.wb_if.cyc <= 1'b0;
        @(posedge wb_if.clk_i);
    endtask

    task single_write(
        input  logic [ADDR_WIDTH-1:0]       addr,
        input  logic [(DATA_WIDTH/8)-1:0]   mask,
        input  logic [DATA_WIDTH-1:0]       write_data
    );
        this.wb_if.adr   <= addr;
        this.wb_if.dat_o <= write_data;
        this.wb_if.we    <= 1'b1;
        this.wb_if.sel   <= mask;
        this.wb_if.stb   <= 1'b1;
        this.wb_if.cyc   <= 1'b1;

        fork
            begin
                // Pipelined -> strobe is deasserted immediately.
                @(posedge wb_if.clk_i);
                this.wb_if.stb <= 1'b0;
            end

            begin
                // We wait for ack (which will be only one).
                @(posedge wb_if.ack);
            end
        join
        
        this.wb_if.cyc <= 1'b0;
        this.wb_if.we  <= 1'b0;
        @(posedge wb_if.clk_i);
    endtask

endclass //wb_sim_master