`include "project.v"

module fire_dedector(input wire [1:0] fire_indicators, output fire_extinguisher);
    //Fire indicators are a smoke dedector which is input 1 at smoke presence
    //and a termometer which is input 1 over 45 degrees Celcius.
    // --------------------------------------------------------
    //Fire dedector on when both indicators are at logic level 1 and then fire
    //extinguisher starts to work. 

    assign fire_extinguisher = fire_indicators[0] & fire_indicators[1];

endmodule
