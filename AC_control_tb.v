`timescale 1ns/1ps

module AC_control_tb();
    // Testbench signals
    reg clk, reset;
    reg button_ac, button_up, button_down;
    reg [6:0] temperature;
    wire [2:0] fan_speed;
    wire [7:0] fan_heat;
    wire [1:0] mode_select;
    wire [6:0] temperature_registered;

    // Instantiate the AC_control module
    AC_control dut (
        .clk(clk),
        .reset(reset),
        .button_ac(button_ac),
        .button_up(button_up),
        .button_down(button_down),
        .temperature(temperature),
        .fan_speed(fan_speed),
        .fan_heat(fan_heat)
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
        button_ac = 0;
        button_up = 0;
        button_down = 0;
        temperature = 7'd22;  // Starting room temperature

        // Initialize waveform dump
        $dumpfile("ac_control_tb.vcd");
        $dumpvars(0, AC_control_tb);

        // Reset sequence
        #20 reset = 1;

        // Test Case 1: OFF Mode (Initial state)
        #20;
        $display("Test Case 1: OFF Mode");
        $display("Fan Speed: %d, Fan Heat: %d", fan_speed, fan_heat);

        // Test Case 2: Switch to Automatic Mode
        #20 button_ac = 1;
        #10 button_ac = 0;
        #20;
        $display("Test Case 2: Automatic Mode");
        $display("Fan Speed: %d, Fan Heat: %d", fan_speed, fan_heat);

        // Test Case 3: Temperature adjustment in Automatic Mode
        #20;
        // Set desired temperature to 24°C
        button_up = 1;
        #10 button_up = 0;
        #10 button_up = 1;
        #10 button_up = 0;
        temperature = 7'd28;  // Current temperature higher than desired
        #20;
        $display("Test Case 3: Automatic Mode - Temperature Adjustment");
        $display("Fan Speed: %d, Fan Heat: %d", fan_speed, fan_heat);

        // Test Case 4: Fast Cool Mode
        #20 button_ac = 1;
        #10 button_ac = 0;
        #20;
        $display("Test Case 4: Fast Cool Mode");
        $display("Fan Speed: %d, Fan Heat: %d", fan_speed, fan_heat);

        // Test Case 5: ECO Mode
        #20 button_ac = 1;
        #10 button_ac = 0;
        #20;
        $display("Test Case 5: ECO Mode");
        $display("Fan Speed: %d, Fan Heat: %d", fan_speed, fan_heat);

        // Test Case 6: Temperature bounds testing
        #20;
        // Try to go beyond maximum temperature
        repeat(10) begin
            button_up = 1;
            #10 button_up = 0;
            #10;
        end
        $display("Test Case 6a: Maximum Temperature Test");
        $display("Temperature Registered: %d", dut.ts1.temperature_registered);

        // Try to go below minimum temperature
        repeat(10) begin
            button_down = 1;
            #10 button_down = 0;
            #10;
        end
        $display("Test Case 6b: Minimum Temperature Test");
        $display("Temperature Registered: %d", dut.ts1.temperature_registered);

        // Test Case 7: Simultaneous button press
        #20;
        button_up = 1;
        button_down = 1;
        #10;
        button_up = 0;
        button_down = 0;
        $display("Test Case 7: Simultaneous Button Press Test");
        $display("Temperature Registered: %d", dut.ts1.temperature_registered);

        // End simulation
        #100;
        $display("Simulation completed");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t reset=%b button_ac=%b mode=%b temp=%d temp_reg=%d fan_speed=%d fan_heat=%d",
                 $time, reset, button_ac, dut.mode_select, temperature, 
                 dut.temperature_registered, fan_speed, fan_heat);
    end

endmodule