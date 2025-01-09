// T Flip-Flop module
module t_ff (
    input clk, reset, T,
    output reg Q
);

    always @ (posedge clk or negedge reset) begin
        if (!reset) 
            Q <= 1'b0;
        else if (T)
            Q <= ~Q;
        else
            Q <= Q;
    end

endmodule

// Frequency Divider module
module freq_divider (
    input clk, reset,
    output clk_out
);
    wire [23:0] ff_out;
    wire [23:0] ff_in;
    assign ff_in[0] = 1'b1;

    genvar i, j;
    generate
        for (j = 1; j < 24; j = j + 1) begin: ff_in_gen
            assign ff_in[j] = ff_in[j-1] & ff_out[j-1];
        end

        for (i = 0; i < 24; i = i + 1) begin: ff_gen
            t_ff tflipflop(
                .clk(clk),
                .reset(reset),
                .T(ff_in[i]),
                .Q(ff_out[i])
            );
        end
    endgenerate

    assign clk_out = ff_out[23];
endmodule

// Counter module
module counter #(
    parameter COUNT_WIDTH = 3
) (
    input clk, reset, timer_signal,
    output reg max_tick
);

    reg [COUNT_WIDTH-1:0] count;
    
    always @ (posedge clk or negedge reset) begin
        if (!reset) begin
            count <= 0;
            max_tick <= 1'b0;
        end
        else if (timer_signal) begin
            if (count == (2**COUNT_WIDTH - 1)) begin
                count <= count;
                max_tick <= 1'b1;
            end
            else begin
                count <= count + 1;
                max_tick <= 1'b0;
            end
        end
        else begin
            count <= count;
            max_tick <= max_tick;
        end
    end
    
endmodule

// Door Control module
module door_control (
    input clk, reset, submit,
    input [13:0] password_in,
    input [13:0] new_password,
    input change_password, unlock_button, ms_button,
    output reg unlock_signal, lock_signal, alarm_signal
);
    // State encoding
    localparam [1:0] PS = 2'b00;  // Password State
    localparam [1:0] MS = 2'b01;  // Menu State
    localparam [1:0] AS = 2'b10;  // Alarm State
    localparam [1:0] CP = 2'b11;  // Change Password State
    
    reg timer_signal;
    reg [1:0] fail_attempts;
    reg [1:0] machine_state;
    reg [13:0] current_password;
    reg [13:0] password_key;
    
    wire max_tick;

    // Initialize password key
    initial begin
        password_key = 14'd1111;
        machine_state = PS;
        fail_attempts = 2'b00;
        current_password = 14'd0;
    end

    // Instantiate counter for alarm timing
    counter #(
        .COUNT_WIDTH(3)
    ) alarm_counter (
        .clk(clk),
        .reset(reset),
        .timer_signal(timer_signal),
        .max_tick(max_tick)
    );

    // Main state machine
    always @ (posedge clk or negedge reset) begin
        if (!reset) begin
            machine_state <= PS;
            fail_attempts <= 2'b00;
            unlock_signal <= 1'b0;
            lock_signal <= 1'b0;
            alarm_signal <= 1'b0;
            timer_signal <= 1'b0;
        end
        else begin
            case (machine_state)
                PS: 
                begin
                    alarm_signal <= 1'b0;
                    unlock_signal <= 1'b0;
                    timer_signal <= 1'b0;
                    lock_signal <= 1'b1;
                    if ( submit ) begin
                        if (password_in == current_password || password_in == password_key) begin
                            machine_state <= MS;
                            fail_attempts <= 2'b00;
                        end
                        else if (password_in != current_password && password_in != password_key) begin 
                            if (fail_attempts == 2'd2) begin  // Check for 3 attempts (0,1,2)
                                machine_state <= AS;
                                fail_attempts <= 2'b00;
                            end
                            else begin
                                fail_attempts <= fail_attempts + 1'b1;
                                machine_state <= PS;
                            end
                        end
                    end
                end

                MS: 
                begin 
                    timer_signal <= 1'b0;
                    alarm_signal <= 1'b0;
                    lock_signal <= 1'b0;

                    if (unlock_button) begin
                        unlock_signal <= 1'b1;
                        machine_state <= MS;
                    end
                    else if (change_password) begin
                        unlock_signal <= 1'b0;
                        machine_state <= CP;
                    end
                end

                AS: 
                begin
                    timer_signal <= 1'b1;
                    alarm_signal <= 1'b1;
                    unlock_signal <= 1'b0;
                    lock_signal <= 1'b1;

                    if (max_tick)
                        machine_state <= PS;
                end

                CP: 
                begin
                    alarm_signal <= 1'b0;
                    timer_signal <= 1'b0;
                    unlock_signal <= 1'b0;
                    lock_signal <= 1'b1;
                    current_password <= new_password;
                    
                    if (ms_button)
                        machine_state <= MS;
                end

                default: 
                begin
                    machine_state <= PS;
                    fail_attempts <= 2'b00;
                    unlock_signal <= 1'b0;
                    lock_signal <= 1'b1;
                    alarm_signal <= 1'b0;
                    timer_signal <= 1'b0;
                end
            endcase
        end
    end
    
endmodule
