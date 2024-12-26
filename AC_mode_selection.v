module AC_mode_selection (
  input clk,
  input rst,
  input button,
  output reg [1:0] current_mode 
);

  localparam MODE_OFF        = 2'b00;
  localparam MODE_AUTOMATIC  = 2'b01;
  localparam MODE_FAST_COOL  = 2'b10;
  localparam MODE_ECO        = 2'b11;

  reg button_prev;
  reg button_pressed;

  always @( posedge clk or negedge rst ) begin 
    if (!rst) begin
      button_prev <= 1'b0;
      button_pressed <= 1'b0; 
    end else begin
      button_prev <= button;
      button_pressed <= button && !button_prev; 
    end
  end

  always @( posedge clk ) begin
    if (button_pressed) begin
      case ( current_mode ) 
        MODE_OFF:        current_mode <= MODE_AUTOMATIC;
        MODE_AUTOMATIC:  current_mode <= MODE_FAST_COOL;
        MODE_FAST_COOL:  current_mode <= MODE_ECO;
        MODE_ECO:        current_mode <= MODE_OFF;
      endcase
    end
  end

endmodule