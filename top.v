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
