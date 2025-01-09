`timescale 1ns / 1ps

module temp_sel (
    input wire clk,
    input wire reset,          // Active low asynchronous reset
    input wire button_up,
    input wire button_down,
    output reg [6:0] temperature_registered
);

    // Temperature limits
    localparam MINTEMP = 6'd18;
    localparam MAXTEMP = 6'd26;
    
    // Button state registers
    reg button_up_prev, button_down_prev;
    wire button_up_pressed, button_down_pressed;
    
    // Edge detection for buttons
    assign button_up_pressed = button_up && !button_up_prev;
    assign button_down_pressed = button_down && !button_down_prev;
    
    // Main sequential logic
    always @(posedge clk or negedge reset) begin
        if (!reset) begin  // Asynchronous active-low reset
            temperature_registered <= MINTEMP;
            button_up_prev <= 1'b0;
            button_down_prev <= 1'b0;
        end
        else begin
            // Update previous button states
            button_up_prev <= button_up;
            button_down_prev <= button_down;
            
            // Handle temperature updates
            if (button_up_pressed && button_down_pressed) begin
                // If both buttons pressed, maintain current temperature
                temperature_registered <= temperature_registered;
            end
            else if (button_up_pressed) begin
                // Increment if not at maximum
                temperature_registered <= (temperature_registered == MAXTEMP) ? MAXTEMP : temperature_registered + 1'b1;
            end
            else if (button_down_pressed) begin
                // Decrement if not at minimum
                temperature_registered <= (temperature_registered == MINTEMP) ? MINTEMP : temperature_registered - 1'b1;
            end
        end
    end

endmodule


module AC_mode_selection (
  input clk,
  input reset,
  input button,
  output reg [1:0] current_mode 
);
  reg button_prev;
  reg button_pressed;

  always @( posedge clk or negedge reset ) begin 
    if (!reset) begin
      button_prev <= 1'b0;
      button_pressed <= 1'b0; 
    end else begin
      button_prev <= button;
      button_pressed <= button && !button_prev; 
    end
  end

  always @(posedge clk or negedge reset) begin
    if (!reset) begin
        current_mode <= 2'b00;
    end else if (button_pressed) begin
        case (current_mode)
            2'b00: current_mode <= 2'b01;
            2'b01: current_mode <= 2'b10;
            2'b10: current_mode <= 2'b11;
            2'b11: current_mode <= 2'b00;
        endcase
    end
  end

endmodule


module AC_control( clk, reset, button_ac, button_up, button_down, temperature, fan_speed, fan_heat );

localparam MODE_OFF        = 2'b00;
localparam MODE_AUTOMATIC  = 2'b01;
localparam MODE_FAST_COOL  = 2'b10;
localparam MODE_ECO        = 2'b11;

input clk, reset, button_ac, button_down, button_up;
input [6:0] temperature;
output reg [2:0] fan_speed;
output reg [7:0] fan_heat;
wire [1:0] temporary_register_mode;
wire [6:0] temporary_register_temp;
reg [1:0] mode_select;
reg [6:0] temperature_registered;

// Fetching the desired mode using AC_mode_selection module
AC_mode_selection ac1( .clk(clk), .reset(reset), .button(button_ac), .current_mode(temporary_register_mode));

// Fetching the desired temperature using temp_sel module
temp_sel ts1(.clk(clk), .reset(reset), .button_down(button_down), .button_up(button_up), .temperature_registered(temporary_register_temp));


always @ (posedge clk ) begin
    mode_select <= temporary_register_mode;
    temperature_registered <= temporary_register_temp;
end



// In order for automatic mode to work, the difference between the temperature registered (by the user) and temperature should be known.
reg [3:0] temp_diff;

always @ ( posedge clk ) begin
    if ( temperature > temperature_registered )
        temp_diff <= temperature - temperature_registered;
    else if ( temperature < temperature_registered )
        temp_diff <= temperature_registered - temperature;
    else
        temp_diff <= 3'd0;
end


always @ ( posedge clk ) begin
    case ( mode_select )
        MODE_OFF : // The system is turned-off
        begin
            fan_speed <= 0;
            fan_heat <= 0;
        end

        MODE_AUTOMATIC : // Automatic Mode
        begin
            if ( (temp_diff > 2) && (temp_diff <= 4) ) begin
                fan_speed <= 3'b001; // Slowest fan speed
                fan_heat <= temperature_registered - 1;
            end
            else if ( (temp_diff > 4) && (temp_diff <= 6) ) begin
                fan_speed <= 3'b010;
                fan_heat <= temperature_registered - 3;
            end
            else if ( (temp_diff > 6) && (temp_diff <= 8) ) begin
                fan_speed <= 3'b011;
                fan_heat <= temperature_registered -5;
            end
            else begin
                fan_speed <= 3'b000;
                fan_heat <= 0;
            end
        end

        MODE_FAST_COOL : // Fast Cooling Mode
        begin 
            fan_speed <= 3'b100; // Fastest fan speed
            fan_heat <= temperature_registered - 5;
        end

        MODE_ECO : // Economy Mode
        begin
            fan_speed <= 3'b010;
            fan_heat <= temperature_registered - 2;
        end
    endcase
end
endmodule


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


module fire (
    input clk, reset,
    input heat_signal, smoke_signal,
    output reg alarm, extinguish
);
    // State encoding
    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] ALARM     = 2'b01;
    localparam [1:0] EXTINGUISH = 2'b10;

    reg [1:0] current_state;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= IDLE;
            alarm <= 1'b0;
            extinguish <= 1'b0;
        end
        else begin
            case (current_state)
                IDLE: 
                begin
                    alarm <= 1'b0;
                    extinguish <= 1'b0;
                    if (smoke_signal)
                        current_state <= ALARM;
                    else
                        current_state <= current_state;
                end

                ALARM: 
                begin
                    alarm <= 1'b1;
                    extinguish <= 1'b0;
                    if (smoke_signal && heat_signal)
                        current_state <= EXTINGUISH;
                    else if (!smoke_signal)
                        current_state <= IDLE;
                    else 
                        current_state <= current_state;
                end

                EXTINGUISH: 
                begin
                    alarm <= 1'b1;
                    extinguish <= 1'b1;
                    if (!(smoke_signal && heat_signal))
                        current_state <= IDLE;
                    else
                        current_state <= current_state;
                end

                default: 
                begin
                    current_state <= IDLE;
                    alarm <= 1'b0;
                    extinguish <= 1'b0;
                end
            endcase
        end
    end

endmodule

module color_sel (
    input wire clk,
    input wire reset,
    input wire color_button,
    output reg [1:0] color
);

    // Define color states using named constants for better readability
    localparam NATURAL = 2'b00; 
    localparam WHITE   = 2'b01;  
    localparam BLUE    = 2'b10;  
    localparam ORANGE  = 2'b11;  
    
    // Signals for button press detection
    wire button_pressed;
    reg button_prev;

    // Edge detection logic
    assign button_pressed = color_button && !button_prev;

    // Main sequential logic block
    always @ (posedge clk or negedge reset) begin
        if (!reset) begin
            // Asynchronous reset condition (reset = 0)
            button_prev <= 1'b0;
            color <= NATURAL;
        end
        else begin
            // Normal operation (reset = 1)
            // Update button history every clock cycle
            button_prev <= color_button;
            
            // Check if a new button press is detected
            if (button_pressed) begin
                // State transition logic using case statement
                // Changes color in sequence: NATURAL -> WHITE -> BLUE -> ORANGE -> NATURAL
                case (color)
                    NATURAL : color <= WHITE;
                    WHITE   : color <= BLUE;
                    BLUE    : color <= ORANGE;
                    ORANGE  : color <= NATURAL;
                endcase
            end
        end
    end
    
endmodule

module light_control (
    input wire clk,
    input wire reset,
    input wire color_button,
    input wire [7:0] sunlight_sensor,
    output reg [1:0] luminosity,
    output reg [1:0] color
);

// Define the possible luminosity states
localparam HIGH_LUMINOSITY = 2'b11;
localparam MID_LUMINOSITY  = 2'b10;
localparam LOW_LUMINOSITY  = 2'b01;
localparam LIGHTS_OFF      = 2'b00;

// Instantiate color_sel to handle color changes
wire [1:0] selected_color; 
color_sel cs(.clk(clk), .reset(reset), .color_button(color_button), .color(selected_color));
always @ ( posedge clk )
    color <= selected_color;
    

// Update luminosity based on the sunlight_sensor value at each rising clock
always @(posedge clk) begin
    if (sunlight_sensor < 8'd15)
        luminosity <= HIGH_LUMINOSITY;   // High brightness if sunlight is low
    else if (sunlight_sensor > 8'd15 & sunlight_sensor < 8'd30)
        luminosity <= MID_LUMINOSITY;    // Medium brightness range
    else if (sunlight_sensor > 8'd30 & sunlight_sensor < 8'd50)
        luminosity <= LOW_LUMINOSITY;    // Low brightness range
    else
        luminosity <= LIGHTS_OFF;        // Default to off
end

endmodule

module top_module (
    input wire clk,
    input wire reset,

    // Inputs for AC Control
    input wire button_ac,
    input wire button_up,
    input wire button_down,
    input wire [6:0] temperature,

    // Inputs for Door Control
    input wire submit,
    input wire change_password,
    input wire unlock_button,
    input wire ms_button,
    input wire [13:0] password_in,
    input wire [13:0] new_password,

    // Inputs for Fire Control
    input wire heat_signal,
    input wire smoke_signal,

    // Inputs for Light Control
    input wire color_button,
    input wire [7:0] sunlight_sensor,

    // Outputs for AC Control
    output wire [2:0] fan_speed,
    output wire [7:0] fan_heat,

    // Outputs for Door Control
    output wire unlock_signal,
    output wire lock_signal,
    output wire alarm_signal,

    // Outputs for Fire Control
    output wire fire_alarm,
    output wire extinguish,

    // Outputs for Light Control
    output wire [1:0] luminosity,
    output wire [1:0] color
);

// Wires for inter-module connections
wire [1:0] ac_mode;
wire [6:0] registered_temperature;

// AC Control Integration
AC_control ac_control_inst (
    .clk(clk),
    .reset(reset),
    .button_ac(button_ac),
    .button_up(button_up),
    .button_down(button_down),
    .temperature(temperature),
    .fan_speed(fan_speed),
    .fan_heat(fan_heat)
);

// Door Control Integration
door_control door_control_inst (
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

// Fire Control Integration
fire fire_inst (
    .clk(clk),
    .reset(reset),
    .heat_signal(heat_signal),
    .smoke_signal(smoke_signal),
    .alarm(fire_alarm),
    .extinguish(extinguish)
);

// Light Control Integration
light_control light_control_inst (
    .clk(clk),
    .reset(reset),
    .color_button(color_button),
    .sunlight_sensor(sunlight_sensor),
    .luminosity(luminosity),
    .color(color)
);

endmodule
