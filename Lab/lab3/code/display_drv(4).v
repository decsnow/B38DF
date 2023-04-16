module display_drv(clk,off,number,display);
/*   0
     -- 
 5  | 6 | 1
     --
 4  |  | 2
     --
     3
     
 Table
 
 	b6    b0
 F      1110001
 E      1111001
 D      1011110
 C      0111001
 B      1111100
 A      1110111  
     
 
*/

input clk, off;   // off display off,  There is no dp decimal point
input [3:0] number; 
output [6:0] display;
reg [6:0] d;

assign display = ~d;   // active low

always @(posedge clk )
// clock edge update display
 begin
 if (~off)
   begin
    case (number)
     4'd0 : d <= 7'b0111111;   // segments lit
     4'd1 : d <= 7'b0000110;
     4'd2 : d <= 7'b1011011;
     4'd3 : d <= 7'b1001111;
     4'd4 : d <= 7'b1100110;
     4'd5 : d <= 7'b1101101;
     4'd6 : d <= 7'b1111101;
     4'd7 : d <= 7'b0000111;
     4'd8 : d <= 7'b1111111;
     4'd9 : d <= 7'b1101111;
     4'ha : d <= 7'b1110111;
     4'hb : d <= 7'b1111100;
     4'hc : d <= 7'b0111001;
     4'hd : d <= 7'b1011110;
     4'he : d <= 7'b1111001;
     4'hf : d <= 7'b1110001;
   endcase
   end  
    else d <= 7'b0000000;    // off
 end

endmodule
