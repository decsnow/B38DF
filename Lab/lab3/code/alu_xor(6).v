module ALU(clk, Ain, Bin, aluControl, AluOut,status,J);
input clk,J;
input [8:0] Ain, Bin;
input [3:0] aluControl;
output [8:0] AluOut;
output [7:0] status;
reg signed [17:0] AluOutI; // internal register to determine overflow
//reg [7:0] status;  // only bits 0 - 3 used
reg G,L,S,O,Z;
// wire[7:0] st;

assign status = {1'b0,1'b0,1'b0, G,L,S,O,Z};  

assign AluOut = AluOutI[8:0];  // only 9 bits connected outside

//   Blocking statements throughout to have immediate effect

always @(posedge clk)
  begin
   if (~J)
   begin
    case (aluControl)
       4'b 0000 : AluOutI = AluOut;  // NOP
       4'b 0010 :  // add
                  begin
                    AluOutI = Ain + Bin;
                  end
       4'b 0011 :  // subtract
                  begin
                     AluOutI = Ain - Bin;
                  end
        4'b0100 : // inc
                  begin
                     AluOutI = Ain + 1'b1;
                  end
         4'b0101 : //dec
                  begin
                     AluOutI = Ain - 1'b1;
                  end
         4'b0110  : // copy 
                    begin
                     AluOutI = Bin;
                    end
         4'b0111 : // multiply
                  begin
                     AluOutI =Ain * Bin;
                  end
         4'b1000 : // bit And
                   begin
                     AluOutI = Ain & Bin;
                   end 
          4'b1001 : // bit XOr
                   begin
                     AluOutI = Ain ^ Bin;
                   end 
          
         
       default   : AluOutI = 8'h000;
      endcase
    end 
 // 
 /*   infer status
 
 Status results
     if (AluOut==0) Z=1      Equal
     if (AluOut < 0) L = 1     less than
     if (AluOut >0)  G = 1     greater than
     if (AluOut > 511)  O = 1
     if (AluOut[8])  S=1   indicating result is negative or output > 1FF
 
*/
   if (AluOutI < 0)  // less than
      begin
       S = 1'b1;  L = 1'b1;
      end
       else begin
         S = 1'b0; L = 1'b0;
      end
   if ((AluOutI[8:0] > 9'h000)  && (S==0))  G= 1'b1;   // greater than 
           else G= 1'b0;
        
   if (AluOutI == 9'h000) Z = 1'b1;  // equal
          else Z = 1'b0;
       
   if (AluOutI > 9'h1FF)
       O = 1'b1;
       else O = 1'b0;
  end  
endmodule 
