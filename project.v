//This is the main file where the common parts of the project are hold.



module mux4to1 (input wire [1:0] sel, input wire [3:0] in, output reg out);
    always @(*)
        begin
            case (sel)
                2'b00: out = in[0]; 
                2'b01: out = in[1]; 
                2'b10: out = in[2]; 
                2'b11: out = in[3]; 
                default: out = 0;
            endcase
        end
endmodule

module mux2to1 (input wire sel, input wire [1:0] in, output reg out);
    always @(*)
        begin
            case (sel)
                1'b0: out = in[0];
                1'b1: out = in[1];
            endcase
        end
endmodule
