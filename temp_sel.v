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