`timescale 1ns / 1ps

module door_control_tb;

    // Inputs
    reg clk;
    reg reset;
    reg submit;
    reg change_password;
    reg unlock_button;
    reg ms_button;
    reg [13:0] password_in;
    reg [13:0] new_password;

    // Outputs
    wire unlock_signal;
    wire lock_signal;
    wire alarm_signal;

    // Instantiate the Door Control module
    door_control uut (
        .clk(clk),
        .reset(reset),
        .submit(submit),
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
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 0;
        submit = 0;
        password_in = 0;
        new_password = 0;
        change_password = 0;
        unlock_button = 0;
        ms_button = 0;

        // Apply reset
        #10 reset = 1;

        // Test case 1: Correct password input
        #10 password_in = 14'd1111;  // Default password
        submit = 1;
        #10 submit = 0;

        // Wait and observe the unlock signal
        #20;

        // Test case 2: Change password
        change_password = 1;
        new_password = 14'd2222;  // New password
        #10 change_password = 0;

        // Test case 3: Incorrect password input (1st attempt)
        password_in = 14'd1234;
        submit = 1;
        #10 submit = 0;

        // Test case 4: Incorrect password input (2nd attempt)
        #20 password_in = 14'd5678;
        submit = 1;
        #10 submit = 0;

        // Test case 5: Incorrect password input (3rd attempt, trigger alarm)
        #20 password_in = 14'd9012;
        submit = 1;
        #10 submit = 0;

        // Observe alarm signal
        #50;

        // Test case 6: Reset system
        reset = 0;
        #10 reset = 1;

        // Test case 7: Unlock using the new password
        password_in = 14'd2222;
        submit = 1;
        #10 submit = 0;

        // Wait and observe the unlock signal
        #20;

        // Test case 8: Return to main menu
        ms_button = 1;
        #10 ms_button = 0;

        // End simulation
        #50 $stop;
    end

endmodule
