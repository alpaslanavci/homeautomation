`timescale 1ns / 1ps

module top_module_tb;

    // Inputs
    reg clk;
    reg reset;
    reg button_ac;
    reg button_up;
    reg button_down;
    reg [6:0] temperature;
    reg submit;
    reg [13:0] password_in;
    reg [13:0] new_password;
    reg change_password;
    reg unlock_button;
    reg ms_button;
    reg heat_signal;
    reg smoke_signal;
    reg color_button;
    reg [7:0] sunlight_sensor;

    // Outputs
    wire [2:0] fan_speed;
    wire [7:0] fan_heat;
    wire unlock_signal;
    wire lock_signal;
    wire alarm_signal;
    wire alarm;
    wire extinguish;
    wire [1:0] luminosity;
    wire [1:0] color;

    // Instantiate the top_module
    top_module uut (
        .clk(clk),
        .reset(reset),
        .button_ac(button_ac),
        .button_up(button_up),
        .button_down(button_down),
        .temperature(temperature),
        .submit(submit),
        .password_in(password_in),
        .new_password(new_password),
        .change_password(change_password),
        .unlock_button(unlock_button),
        .ms_button(ms_button),
        .heat_signal(heat_signal),
        .smoke_signal(smoke_signal),
        .color_button(color_button),
        .sunlight_sensor(sunlight_sensor),
        .fan_speed(fan_speed),
        .fan_heat(fan_heat),
        .unlock_signal(unlock_signal),
        .lock_signal(lock_signal),
        .alarm_signal(alarm_signal),
        .extinguish(extinguish),
        .luminosity(luminosity),
        .color(color)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 time units clock period

    // Testbench initialization
    initial begin
        // Initialize inputs
        reset = 1; // Initialize reset high
        button_ac = 0;
        button_up = 0;
        button_down = 0;
        temperature = 7'd25;
        submit = 0;
        password_in = 14'd0;
        new_password = 14'd0;
        change_password = 0;
        unlock_button = 0;
        ms_button = 0;
        heat_signal = 0;
        smoke_signal = 0;
        color_button = 0;
        sunlight_sensor = 8'd0;

        // Reset the system (active low reset)
        #10; // Wait for a few clock cycles before deasserting reset
        reset = 0;
        #10;
        reset = 1;

        // Test AC Control
        button_ac = 1; #10; button_ac = 0; // Toggle AC
        repeat(3) begin // Test multiple up/down presses
          button_up = 1; #10; button_up = 0; // Increase temperature
          button_down = 1; #10; button_down = 0; // Decrease temperature
        end

        // Test Door Control
        repeat (3) begin
        password_in = 14'd1234; // Incorrect password
        submit = 1; #10; submit = 0;
        #100; // Delay to observe outputs (e.g., lock signal, alarm)
        end

        password_in = 14'd1111; // Correct password
        submit = 1; #10; submit = 0;
        #10;
        unlock_button = 1; #10; unlock_button = 0; // Unlock the door
        #10;

        // Test Fire Detection
        heat_signal = 1; smoke_signal = 1; #10; // Trigger alarm and extinguish
        #10;
        heat_signal = 0; smoke_signal = 0; #10; // Clear alarm
        #10;
        smoke_signal = 1; #10; smoke_signal = 0;
        #10;



        // Test Light Control
        repeat(4) begin // Cycle through colors
            color_button = 1; #10; color_button = 0; // Change color
            #10;
        end
        sunlight_sensor = 8'd10; #10; // High luminosity
        sunlight_sensor = 8'd20; #10; // Medium luminosity
        sunlight_sensor = 8'd40; #10; // Low luminosity
        sunlight_sensor = 8'd60; #10; // Lights off
        sunlight_sensor = 8'd0; #10; // Lights on again


        // End simulation
        $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule
