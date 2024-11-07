`include "project.v"

module heatSystems_control (input wire [1:0] mode, input wire mode_select, output selected_mode);
    //There is a 2to1 Multiplexer for the present 2 modes of heating systems. According to select inputs
    //one of the mods will be selected.

    wire mux_out;       
    2to1mux heatSystems_mode_selector(.sel(mode_select), .in(mode), .out(mux_out));
    always @(*)
        select_mode = mux_out;

endmodule