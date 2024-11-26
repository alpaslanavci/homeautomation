`include "project.v"

module AC_control(input wire [1:0] mode_selection, input wire [3:0] mode, output reg selected_mode);
    //There is a 4to1 Multiplexer for the present 4 modes of AC. According to select inputs
    //one of the mods will be selected.

    wire mux_out;
    mux4to1 ac_mode_selector(.sel(mode_selection), .in(mode), .out(mux_out));

    always @(*)
        selected_mode = mux_out

endmodule
