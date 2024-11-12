`default_nettype none

/*
Basic input debouncer. Good for very noisy input sources, such as
microswitch buttons.

The debouncing logic works as following:
1. When change on input is deteceted, the timer is started.
2. If there is another changes before timer reaches the top, it is restarted.
3. After the timer successfully reaches the top, input will be forwarded and the timer will be stopped.

TIMER_WIDTH should be configured depending on input clock speed.
*/
module debouncer_block #(
    parameter TIMER_WIDTH
) (
    input wire logic clk,
    input wire logic rst,
    input wire logic in,

    output logic     out
);
    logic [TIMER_WIDTH-1:0] timer_val;
    logic                   timer_top;
    logic                   timer_en;
    logic                   prev_input;
    
    always_ff @( posedge clk ) begin : timer_proc
        if (
            rst || (in != prev_input)
        ) begin
            timer_val  <= 'h0;
            prev_input <= in;
        end else if (timer_en) begin
            timer_val <= timer_val + 1;
        end
    end

    always_ff @( posedge clk ) begin : debounced_forward_proc
        if (rst) begin
            out <= 'h0;
        end else if (timer_top == 1'b1) begin
            out  <= prev_input;
        end
    end

    // Let's save some logic and compare only highest and lowest bit.
    // We don't need better precision anyway.
    assign timer_top =  timer_val[TIMER_WIDTH-1] == 1'b1 && timer_val[0] == 1'b0;
    // The timer will stop after reaching top. It will be restarted
    // when the input changes.
    assign timer_en  = (timer_val[TIMER_WIDTH-1] == 1'b1 && timer_val[0] == 1'b1) ? 1'b0 : 1'b1;

endmodule