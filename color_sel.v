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