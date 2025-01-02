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
    if (!rst) begin
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
wire [1:0] temporary_register_mode, mode_select;
wire [6:0] temporary_register_temp, temperature_registered;

// Fetching the desired mode using AC_mode_selection module
AC_mode_selection ac1( .clk(clk), .reset(reset), .button(button_ac), .current_mode(temporary_register_mode));

// Fetching the desired temperature using temp_sel module
temp_sel ts1(.clk(clk), .reset(reset), .button_down(button_down), .button_up(button_up), .temperature_registered(temporary_register_temp));


always @ (posedge clk ) begin
    mode_select <= temporary_register_mode;
    temperature_registered <= temperature_registered;
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
