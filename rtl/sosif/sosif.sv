/*
SOSIF: SOftware-Simulator InterFace
Non-synthesizable.

This module is an interface between software running on the VESP and the simulator.
Basically it allows to control simulation from inside the program.
*/
module module_sosif (
    wishbone_if.slave    wb,
    output  logic [15:0] irq_bus
);

    string msg_buf;

    initial begin
        wb.ack  = 1'b0;
        irq_bus = 'h0;
    end

    always @( posedge wb.clk_i ) begin

        if (wb.rst_i) begin
            wb.ack  = 1'b0;
            irq_bus = 'h0;
        end else if (wb.cyc && wb.stb & wb.we) begin
            wb.ack = 1'b1;

            if (wb.sel != 4'b1111) begin
                $display("[SOSIF] Warning: Invalid WB sel signal. Only word-wide writes are allowed.");
            end

            // Process OP
            casez (wb.dat_i[7:0])
                // NOP
                8'h0:;

                /////////////////////////////////////////////////////
                // Simulation control
                // We use $display to show these messages always
                // independetly on severity level.
                /////////////////////////////////////////////////////
                8'h1: begin
                $display("[SOSIF] Halting simulation: unknown reason."); 
                $finish;
                end
                8'h2: begin
                    $display("[SOSIF] Halting simulation: TEST PASS (SOSIF_TEST_PASS)");
                    $finish;
                end
                8'h3: begin
                    $display("[SOSIF] Halting simulation: TEST FAIL (SOSIF_TEST_FAIL)");
                    $finish;
                end

                /////////////////////////////////////////////////////
                // Message passing
                // Here we use verbosity based output functions,
                // which also print out simulation time.
                /////////////////////////////////////////////////////
                // Put character to a message buffer.
                8'h10: begin
                    msg_buf = {msg_buf, $sformatf("%c", wb.dat_i[15:8])};
                end
                // Flush message buffer, severity info.
                8'h11: begin
                    $info("[SOSIF LOG] %s", msg_buf);
                end
                // Flush message buffer, severity warning.
                8'h12: begin
                    $warning("[SOSIF LOG] %s", msg_buf);
                end
                // Flush message buffer, severity error.
                8'h13: begin
                    $error("[SOSIF LOG] %s", msg_buf);
                end

                /////////////////////////////////////////////////////
                // In-program IRQ control
                /////////////////////////////////////////////////////
                8'h20: begin
                    irq_bus = wb.dat_i[23:8];
                end

                /////////////////////////////////////////////////////
                // Other
                /////////////////////////////////////////////////////
                default: begin
                    $error("[SOSIF] Invalid command!");
                end 
            endcase        
        end else begin
            wb.ack = 1'b0;
        end

    end
    
endmodule