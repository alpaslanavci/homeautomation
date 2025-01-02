`timescale 1ns/1ps

module door_control_tb();
    reg clk, reset;
    reg [13:0] password_in;
    reg [13:0] new_password;
    reg change_password, unlock_button, ms_button;
    wire unlock_signal, lock_signal, alarm_signal;

    // State parameters 
    localparam [1:0] PS = 2'b00;  
    localparam [1:0] MS = 2'b01;  
    localparam [1:0] AS = 2'b10;  
    localparam [1:0] CP = 2'b11;  

    // Instantiate the door_control module
    door_control dut (
        .clk(clk),
        .reset(reset),
        .password_in(password_in),
        .new_password(new_password),
        .change_password(change_password),
        .unlock_button(unlock_button),
        .ms_button(ms_button),
        .unlock_signal(unlock_signal),
        .lock_signal(lock_signal),
        .alarm_signal(alarm_signal)
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
        password_in = 14'd0;
        new_password = 14'd0;
        change_password = 0;
        unlock_button = 0;
        ms_button = 0;

        // Test Case 1: Reset and Initial State
        $display("\nTest Case 1: Reset and Initial State Check");
        #20 reset = 1;
        #10;
        $display("Initial State - Lock: %b, Unlock: %b, Alarm: %b", 
                lock_signal, unlock_signal, alarm_signal);

        // Test Case 2: Correct Password Entry (Master Key)
        $display("\nTest Case 2: Correct Master Password Entry");
        password_in = 14'd1111;  // Master key
        #20;
        $display("After Correct Password - Lock: %b, Unlock: %b, Alarm: %b", 
                lock_signal, unlock_signal, alarm_signal);

        // Test Case 3: Unlock Button in Menu State
        $display("\nTest Case 3: Unlock Button Test");
        unlock_button = 1;
        #20;
        $display("After Unlock Button - Lock: %b, Unlock: %b, Alarm: %b", 
                lock_signal, unlock_signal, alarm_signal);
        unlock_button = 0;

        // Test Case 4: Password Change Sequence
        $display("\nTest Case 4: Password Change Test");
        change_password = 1;
        #20;
        new_password = 14'd2222;
        #20;
        ms_button = 1;
        #20;
        $display("After Password Change - New Password Set: %d", dut.current_password);
        change_password = 0;
        ms_button = 0;

        // Test Case 5: Failed Password Attempts
        $display("\nTest Case 5: Failed Password Attempts Test");
        password_in = 14'd3333;  // Wrong password
        repeat(3) begin
            #20;
            $display("Attempt %d - Lock: %b, Unlock: %b, Alarm: %b", 
                    dut.fail_attempts + 1, lock_signal, unlock_signal, alarm_signal);
        end

        // Test Case 6: Alarm State Duration
        $display("\nTest Case 6: Alarm State Duration Test");
        #200;  // Wait for alarm counter
        $display("After Alarm Timeout - Lock: %b, Unlock: %b, Alarm: %b", 
                lock_signal, unlock_signal, alarm_signal);

        // Test Case 7: New Password Verification
        $display("\nTest Case 7: New Password Verification");
        password_in = 14'd2222;  // Using new password
        #20;
        $display("Using New Password - Lock: %b, Unlock: %b, Alarm: %b", 
                lock_signal, unlock_signal, alarm_signal);

        // Test Case 8: Reset During Operation
        $display("\nTest Case 8: Reset During Operation Test");
        reset = 0;
        #20;
        reset = 1;
        $display("After Reset - Lock: %b, Unlock: %b, Alarm: %b", 
                lock_signal, unlock_signal, alarm_signal);

        // End simulation
        #100;
        $display("\nSimulation completed");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t reset=%b state=%b password=%d new_pass=%d fail_attempts=%d alarm=%b unlock=%b lock=%b",
                 $time, reset, dut.machine_state, password_in, new_password, 
                 dut.fail_attempts, alarm_signal, unlock_signal, lock_signal);
    end

endmodule