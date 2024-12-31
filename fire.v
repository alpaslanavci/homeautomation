module fire (
    input clk, reset,
    input heat_signal, smoke_signal,
    output reg alarm, extinguish
);
    // State encoding
    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] ALARM     = 2'b01;
    localparam [1:0] EXTINGUISH = 2'b10;

    reg [1:0] current_state;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= IDLE;
            alarm <= 1'b0;
            extinguish <= 1'b0;
        end
        else begin
            case (current_state)
                IDLE: 
                begin
                    alarm <= 1'b0;
                    extinguish <= 1'b0;
                    if (smoke_signal)
                        current_state <= ALARM;
                    else
                        current_state <= current_state;
                end

                ALARM: 
                begin
                    alarm <= 1'b1;
                    extinguish <= 1'b0;
                    if (smoke_signal && heat_signal)
                        current_state <= EXTINGUISH;
                    else if (!smoke_signal)
                        current_state <= IDLE;
                    else 
                        current_state <= current_state;
                end

                EXTINGUISH: 
                begin
                    alarm <= 1'b1;
                    extinguish <= 1'b1;
                    if (!(smoke_signal && heat_signal))
                        current_state <= IDLE;
                    else
                        current_state <= current_state;
                end

                default: 
                begin
                    current_state <= IDLE;
                    alarm <= 1'b0;
                    extinguish <= 1'b0;
                end
            endcase
        end
    end

endmodule