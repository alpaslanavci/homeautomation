`include "color_sel.v"

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
color_sel cs(
    .clk(clk),
    .reset(reset),
    .color_button(color_button),
    .color(color)
);

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