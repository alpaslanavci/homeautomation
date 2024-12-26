`include "AC_mode_selection.v"
`include "temp_sel.v"

module AC_control( clk, reset, button_ac, button_up, button_down, temperature, temperature_registered, mode_select_ac, fan_speed, fan_heat );

input clk, reset, button_ac, button_down, button_up;
input [1:0] mode_select;
input [6:0] temperature;
input [6:0] temperature_registered;
output reg [2:0] fan_speed;
output reg [7:0] fan_heat;

// Fetching the desired mode using AC_mode_selection module
AC_mode_selection ac1( .clk(clk), .reset(reset), .button(button_ac), .mode(mode_select));

// Fetching the desired temperature using temp_sel module
temp_sel ts1(.clk(clk), .reset(reset), .button_down(button_down), .button_up(button_up), .temperature_registered(temperature_registered));


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
        2'b00 : // The system is turned-off
        begin
            fan_speed <= 0;
            fan_heat <= 0;
        end

        2'b01 : // Automatic Mode
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

        2'b10 : // Fast Cooling Mode
        begin 
            fan_speed <= 3'b100; // Fastest fan speed
            fan_heat <= temperature_registered - 5;
        end

        2'b11 : // Economy Mode
        begin
            fan_speed <= 3'b010;
            fan_heat <= temperature_registered - 2;
        end
    endcase
end
endmodule
