class wb_sim_master #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32,
    parameter GRANULARITY = 8
);
    
    virtual wishbone_if.master wb_if;

    function new(virtual wishbone_if.master wb_if);
        this.wb_if = wb_if;
    endfunction

    task single_read(
        input  logic [ADDR_WIDTH-1:0]       addr,
        input  logic [(DATA_WIDTH/8)-1:0]   mask,
        output logic [DATA_WIDTH-1:0]       read_data
    );
        this.wb_if.adr = addr;
        this.wb_if.we  = 1'b0;
        this.wb_if.sel = mask;
        this.wb_if.stb = 1'b1;
        this.wb_if.cyc = 1'b1;

        do begin
            @(posedge wb_if.clk);
        end while(this.wb_if.ack == 1'b0);

        this.wb_if.stb = 1'b0;
        this.wb_if.cyc = 1'b0;
        read_data      = this.wb_if.dat_i;
        @(posedge wb_if.clk);
        
    endtask

    task single_write(
        input  logic [ADDR_WIDTH-1:0]       addr,
        input  logic [(DATA_WIDTH/8)-1:0]   mask,
        input  logic [DATA_WIDTH-1:0]       write_data
    );

    endtask

endclass //wb_sim_master