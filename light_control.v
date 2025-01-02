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
wire [1:0] selected_color 
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