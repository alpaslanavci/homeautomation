`timescale 1ns/1ps

module light_control_tb();
    reg clk, reset;
    reg color_button;
    reg [7:0] sunlight_sensor;
    wire [1:0] luminosity;
    wire [1:0] color;

    // Instantiate the light_control module
    light_control dut (
        .clk(clk),
        .reset(reset),
        .color_button(color_button),
        .sunlight_sensor(sunlight_sensor),
        .luminosity(luminosity),
        .color(color)
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
        color_button = 0;
        sunlight_sensor = 8'd20;  // Initial sunlight value

        // Reset sequence
        #20 reset = 1;

        // Test Case 1: Initial state check
        #20;
        $display("Test Case 1: Initial State");
        $display("Color: %b, Luminosity: %b", color, luminosity);

        // Test Case 2: Color cycle test
        $display("\nTest Case 2: Color Cycle Test");
        
        // Test all color transitions
        repeat(4) begin
            #20 color_button = 1;
            #10 color_button = 0;
            #10;
            $display("Color: %b", color);
        end

        // Test Case 3: Luminosity levels based on sunlight
        $display("\nTest Case 3: Luminosity Level Test");
        
        // Test HIGH_LUMINOSITY (sunlight < 15)
        #20 sunlight_sensor = 8'd10;
        #10;
        $display("Sunlight: %d, Luminosity: %b (Expected: HIGH)", 
                sunlight_sensor, luminosity);

        // Test MID_LUMINOSITY (15 < sunlight < 30)
        #20 sunlight_sensor = 8'd20;
        #10;
        $display("Sunlight: %d, Luminosity: %b (Expected: MID)", 
                sunlight_sensor, luminosity);

        // Test LOW_LUMINOSITY (30 < sunlight < 50)
        #20 sunlight_sensor = 8'd40;
        #10;
        $display("Sunlight: %d, Luminosity: %b (Expected: LOW)", 
                sunlight_sensor, luminosity);

        // Test LIGHTS_OFF (sunlight > 50)
        #20 sunlight_sensor = 8'd60;
        #10;
        $display("Sunlight: %d, Luminosity: %b (Expected: OFF)", 
                sunlight_sensor, luminosity);

        // Test Case 4: Rapid color button presses
        $display("\nTest Case 4: Rapid Button Press Test");
        repeat(3) begin
            #5 color_button = 1;
            #5 color_button = 0;
        end
        #10;
        $display("Final Color after rapid presses: %b", color);

        // Test Case 5: Boundary conditions for sunlight sensor
        $display("\nTest Case 5: Boundary Conditions Test");
        
        // Test minimum value
        #20 sunlight_sensor = 8'd0;
        #10;
        $display("Minimum sunlight (0): Luminosity = %b", luminosity);
        
        // Test maximum value
        #20 sunlight_sensor = 8'd255;
        #10;
        $display("Maximum sunlight (255): Luminosity = %b", luminosity);

        // Test Case 6: Color selection during different luminosity levels
        $display("\nTest Case 6: Color Selection with Different Luminosity");
        
        // Change color at different luminosity levels
        sunlight_sensor = 8'd10;  // HIGH_LUMINOSITY
        #20 color_button = 1;
        #10 color_button = 0;
        #10;
        $display("Color at HIGH luminosity: %b", color);
        
        sunlight_sensor = 8'd60;  // LIGHTS_OFF
        #20 color_button = 1;
        #10 color_button = 0;
        #10;
        $display("Color at LIGHTS_OFF: %b", color);

        // End simulation
        #100;
        $display("\nSimulation completed");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t reset=%b color_button=%b sunlight=%d color=%b luminosity=%b",
                 $time, reset, color_button, sunlight_sensor, color, luminosity);
    end

endmodule