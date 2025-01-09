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
    always #5 clk = ~clk;  // Clock with a period of 10 ns

    // Test sequence
    initial begin
        // Initial values
        clk = 0;
        reset = 0;
        submit = 0;
        password_in = 0;
        new_password = 0;
        change_password = 0;
        unlock_button = 0;
        ms_button = 0;

        // Reset system
        #10 reset = 1;

        // Test Case 1: Submit an incorrect password (1st attempt)
        #20 password_in = 14'd1234;
        submit = 1;
        #10 submit = 0;

        // Test Case 2: Submit another incorrect password (2nd attempt)
        #20 password_in = 14'd5678;
        submit = 1;
        #10 submit = 0;

        // Test Case 3: Submit an incorrect password (3rd attempt - trigger alarm)
        #20 password_in = 14'd9999;
        submit = 1;
        #10 submit = 0;

        #50;

        // Test Case 4: Reset the system after alarm
        reset = 0;
        #10 reset = 1;

        // Test Case 5: Submit the default password (correct input)
        #10 password_in = 14'd1111;  // Default password
        submit = 1;
        #10 submit = 0;

        // Wait to observe system response
        #20;

        // Test Case 6: Change the password
        #10 change_password = 1;
        new_password = 14'd2222;  // New password
        #10 change_password = 0;
        #10 ms_button = 1; // Return to menu state
        #10 ms_button = 0;

        // Reset the system to return to password state
        reset = 0;
        #10 reset = 1;


        // Test Case 7: Submit the new password 
        #10 password_in = 14'd2222;
        submit = 1;
        #10 submit = 0;

        // Wait to observe system response
        #20;

        // Test Case 8: Unlock button functionality in menu state
        #10 unlock_button = 1;
        #10 unlock_button = 0;


        // End simulation
        #50 $stop;
    end

endmodule
