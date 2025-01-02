`timescale 1ns/1ps

module fire_tb();
    // Testbench signals
    reg clk, reset;
    reg heat_signal, smoke_signal;
    wire alarm, extinguish;
    
    // State parameters for readability in test results
    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] ALARM     = 2'b01;
    localparam [1:0] EXTINGUISH = 2'b10;

    // Instantiate the fire module
    fire dut (
        .clk(clk),
        .reset(reset),
        .heat_signal(heat_signal),
        .smoke_signal(smoke_signal),
        .alarm(alarm),
        .extinguish(extinguish)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 0;
        heat_signal = 0;
        smoke_signal = 0;

        // Initialize waveform dump
        $dumpfile("fire_tb.vcd");
        $dumpvars(0, fire_tb);

        // Test Case 1: Reset and Initial State
        $display("\nTest Case 1: Reset and Initial State Check");
        #20 reset = 1;
        #10;
        $display("Initial State - Alarm: %b, Extinguish: %b", alarm, extinguish);

        // Test Case 2: Smoke Detection Only
        $display("\nTest Case 2: Smoke Detection Only");
        #20 smoke_signal = 1;
        #20;
        $display("Smoke Only - Alarm: %b, Extinguish: %b", alarm, extinguish);
        
        // Return to IDLE
        smoke_signal = 0;
        #20;

        // Test Case 3: Full Fire Condition
        $display("\nTest Case 3: Full Fire Condition (Heat + Smoke)");
        smoke_signal = 1;
        #20;
        $display("Heat + Smoke - Alarm: %b, Extinguish: %b", alarm, extinguish);

        // Test Case 4: Fire Extinction
        $display("\nTest Case 4: Fire Extinction Sequence");
        #40 heat_signal = 0;
        #20;
        $display("After Heat Removed - Alarm: %b, Extinguish: %b", alarm, extinguish);
        #20 smoke_signal = 0;
        #20;
        $display("After Smoke Cleared - Alarm: %b, Extinguish: %b", alarm, extinguish);

        // Test Case 5: State Transition Sequence
        $display("\nTest Case 5: Full State Transition Sequence");
        #20 smoke_signal = 1;    // Should go to ALARM
        #20;
        $display("IDLE->ALARM - Alarm: %b, Extinguish: %b", alarm, extinguish);
        heat_signal = 1;         // Should go to EXTINGUISH
        #20;
        $display("ALARM->EXTINGUISH - Alarm: %b, Extinguish: %b", alarm, extinguish);
        heat_signal = 0;         // Should go back to IDLE
        smoke_signal = 0;
        #20;
        $display("EXTINGUISH->IDLE - Alarm: %b, Extinguish: %b", alarm, extinguish);

        // End simulation
        #100;
        $display("\nSimulation completed");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t reset=%b smoke=%b heat=%b state=%b alarm=%b extinguish=%b",
                 $time, reset, smoke_signal, heat_signal, dut.current_state, alarm, extinguish);
    end

endmodule