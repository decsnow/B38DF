module slowClock(clk,sClock);

input clk;
output sClock;
// clock inputs can be 50, 27, 24MHz from DE1 board
reg [24:0] divCount;
reg slowClock;
reg [8:0] count;

parameter CLOCK =24000000;  // MHz
parameter tenHz = 100;

parameter n = CLOCK/tenHz;

assign sClock = slowClock;

always @ ( posedge clk)
  begin
     divCount = divCount + 1'b1;
     if (divCount > n)
        begin
         divCount = 25'd0;
         slowClock = slowClock ^ 1'b1;
        end
  end


 endmodule
