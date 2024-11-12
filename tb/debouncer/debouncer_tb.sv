`default_nettype none

/*
This testbench simulates a real button (random bouncing on state change) and check
debouncer properties via formal checks.
*/
module debouncer_tb ();
    
    localparam BTN_INSTABILITY_LENGTH = 8;
    localparam DEBOUNCER_TIMER_WIDTH  = 4;
    localparam MAX_TIME_TO_REACH_OUT  = BTN_INSTABILITY_LENGTH + (2**DEBOUNCER_TIMER_WIDTH);

    import tb_pkg::wb_p_sim_master;

    logic             clk, rst;

    logic             btn_pressed;
    logic             btn_out;
    logic             debounced_readout;

    wb_p_sim_master dut_if;
    
    wishbone_p_if wb_if(
        .clk_i(clk),
        .rst_i(rst)
    );

    wb_debouncer #(
        .PORT_CNT(1),
        .TIMER_WIDTH(DEBOUNCER_TIMER_WIDTH)
    ) dut(
        .wb(wb_if.slave),
        .input_ports(btn_out)
    );
    
    module sim_button #(
        parameter INSTABILITY_LENGTH
    ) (
        input  wire logic clk,
        input  wire logic pressed,
        output      logic out
    );
        initial begin
            out       = 0;
        end

        always @(pressed) begin
            for (int i = 0; i < INSTABILITY_LENGTH; i++) begin
                out = $urandom_range(0, 1);
                @(posedge clk);
            end
            out = pressed;
        end
    endmodule

    sim_button #(
        .INSTABILITY_LENGTH(BTN_INSTABILITY_LENGTH)
    ) button (
        .clk(clk),
        .pressed(btn_pressed),
        .out(btn_out)
    );

    initial begin

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

        // Simulate a few button presses and let the formal checker do its job.
        btn_pressed = 1;
        #MAX_TIME_TO_REACH_OUT;
        for (int i = 0; i < 16; i++) begin
            btn_pressed = ~btn_pressed;
            #MAX_TIME_TO_REACH_OUT;
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

    // Mirror register to local variable.
    always @(posedge clk) begin
        logic [31:0] wb_out_data;
        dut_if.single_read('h0, 4'b1111, wb_out_data);

        debounced_readout = wb_out_data[0];
    end

    // The debouncer has these properties:
    // 1. After the input changes, the output should reflect this change. This depends on button instability.
    //      This can't be predicted in the real world, here we can calculate this based on INSTABILITY_LENGTH and TIMER_WIDTH.
    // 2. If the input didn't change, the output should stay at the same value.

    // Property 1.
    // 
    rise_after_input_rises : assert property (
        @(posedge clk) $rose(btn_pressed) |-> ##[0:MAX_TIME_TO_REACH_OUT] $rose(debounced_readout)
    );
    fall_after_input_falls : assert property (
        @(posedge clk) $fell(btn_pressed) |-> ##[0:MAX_TIME_TO_REACH_OUT] $fell(debounced_readout)
    );

    // Property 2.
    keep_high_until_input_falls : assert property (
        @(posedge clk) $rose(debounced_readout) |-> debounced_readout until_with $fell(btn_pressed)
    );
    keep_low_until_input_rises : assert property (
        @(posedge clk) $fell(debounced_readout) |-> !debounced_readout until_with $rose(btn_pressed)
    );


endmodule