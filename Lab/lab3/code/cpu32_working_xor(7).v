module DF(clk,CO,I, rst,PC,aluc,wA,rA,dEn,aOp,dOen,dataRegister,DataAdr,A,B, ALUresult,st,IOport,IOcontrol,p,J);
// cpu32.v no states just a six phase clock
// 1  - fetch 
// 2  - decode
// 3  - execut / read registers
// 3  - compute 
// 4  - data registers operation / alu operation
// 5  -
// 6  - write registers
// 9/2/14 functioning including data output to port   - still a glitch before outupt  to correct ( because output is not clocked   
//        not checked data read from the  port
// Jump instruction  forward and backwards OK
// Conditional jumps no functions  however when compiled under Quartus 9.1 it does not jump out of the loop on the Z flag 
// 19/2/14  in Q 9.1 the Z  flag is set latter whereas und Q 7.1 it is set at begining of the fourth clock 
// Now eliminated redundant test line J now controls the alu operation  giving time JZ to react to the Z flag condition.
// Ok on Q 7.1 and Q9.1
// 11/3/14 corrected bug of inability to write data back to the dataregister.
// 12/3/14  port read fix
// 14/3/14 added JL instruction
// 29/3/14  copy implemented
// 31/3/14  during jump instructions the rdNWrt data register line is set to 0 which forces data register output to high Z  if the next instruction is
//          arithmetical operation the register value may change to 1FF ( the value read from a high-Z bus ) this will be seen as -1 decimal
//          the work around is to set the rdNWrt to 1 ( a read ) set the data register to a defined output - see code 
// 20/4/15 Alu module upadated to fix signed arithmetic for  < flags.
// 31/3/16  fixed bug where R0 was being currupted during an increment operation.   The condition for a write to occur to the ALU register is any 
//          instruction that requires a register change i.e LD Rx.. and ALU operations.  So the regOp line should be set for Load and ALU operations
//           The alu registers are gated with ~J and RegAct to allow a write action
//          actually the Jump line is superfluous in the register module it is only register activity is required to prevent unintended writes
input clk,rst;
output dEn,aOp,IOcontrol,dOen,p,J;
output [5:0] CO;
output [8:0] ALUresult;
output [7:0] st;
output [8:0] dataRegister, A,B;
output [23:0] I;
output signed  [7:0] PC;
output [3:0] DataAdr;
output [4:0] aluc;
output [2:0] wA;
output [2:0] rA;
inout  [8:0] IOport;
//   this version with IO
//inout [8:0] IOcon;
/*
Instruction 
In nibble fields
23 ….20   20….16      15..12       11….8   7….4        3….0
IIII      xWWW       Reg/Data RRR  DDDD  xRegOp        xxxx        x = reserved for future use
                                            Rd/Wd 
                                             IOen  

1010,   PPPP          PPPP,            XXXXXXXXX     unconditional Jump
1011    pppp          pppp                           conditional jump when result = 0 used in conjuction with ucJ

where IIII is the instruction 
J is jump
WWW write address registers
RRR read address registers
RegOp line must be set for any register operation eg Loads and ALU ops 
Reg/Data  = select register or datainput
DDDD data address
Rd/Wd  read not write data memories
IOen  IO enable
AAAA alu control
xor added no display
fixed L flag bug
fixed ALU condition

*/


wire [23:0] instruction;
//reg [5:0] programme_counter;
wire IOen;
wire[3:0] alu_control;
wire [2:0] RA, WA;
wire [3:0] DA;
// reg J,IOen,rdNwrt,regDat,rDNWrD,clk2,RegOp,executing;
wire [3:0] op;
// reg [2:0] operandD, operandS;
// reg [2:0] state;
wire [7:0] status;
wire [8:0] portIO;
wire dOen, clkd,rdNwrt,regDat,rDNWrD,clk2,RegOp,executing,IOrq;
wire [5:0] clockOut,programme_counter;


//parameter LD = 4'd1, ADD=4'd2,SUB=4'd3, INC=4'd4,DEC=4'd5, COP = 4'd6, MUL = 4'd7,NOP =4'd0;
//parameter Fetch = 3'd1,  Decode = 3'd4 ,  Execute = 3'd6;


         
wire [8:0] alu, dataIn,outA,outB;

assign I = instruction;
assign PC = programme_counter;
assign aluc = alu_control;
assign rA =RA;
assign wA = WA;
assign ALUresult = alu;
assign st = status;
assign dOen = 1'b0;//IOen;
assign dataRegister = dataIn;
assign DataAdr = DA; 
assign A = outA;
assign B = outB;
assign dEn = rDNWrD;
assign aOp = RegOp;    // 
assign IOcontrol = IOrq;

assign p = pass;
// assign portIO = DA
assign CO = clockOut;
buf (strong1) b1(clkBuf1,clockOut[0]);
buf (strong1) b2 (clkBuf2,clockOut[1]);
buf (strong1) b3  (clkBuf3, clockOut[2]);
buf (strong1) b4  (clkBuf4, clockOut[3]);
buf (strong1) b5  (clkBuf5, clockOut[4]);
buf (strong1) b6  (clkBuf6, clockOut[5]);


// wire up cpu
clockGen CG1 (rst,clk,clockOut);
//module fetch (clk,rst,instruction,programme_counter,status,pass);
fetch ftch1 (clkBuf1,rst,instruction,programme_counter,status,pass,J);  
// module decode (clk,instruction,WA,RA,regDat,DA,RegOp,rNWrD,operation  ) ;
decode dc1 (clkBuf2,instruction,WA,RA,regDat,DA,RegOp,rDNWrD,op);
// module execute(clk,operation, alu_control, noWrite);
// the test net signals that status is being tested and no register writes are allowed
execute ex1 (clkBuf3,op,alu_control);
//registers (clk1,clk2,regDat, aluIn,dataIn,wrAdd,readAdd1,readAdd2,RegOp,outAreg, outBreg, J); J line not required
registers RG1 (clkBuf3,clkBuf6,regDat, alu,dataIn,WA,WA,RA,RegOp,outA, outB);
//module dataRegisters(clk,dataIn, dataOut, DA, RdNwrt,IOrequest,IOen);
dataRegisters DA1(clkBuf4,outB, dataIn, DA, rDNWrD,IOrq);
//module dataPort(portIO, dataBus, IOaddress, RdNwrt,IOrequest, IOen);
dataPort DP1 (IOport, dataIn,DA, rDNWrD,IOrq); 
//module ALU(clk, Ain, Bin, aluControl, AluOut,status,J);
ALU  ALU1(clkBuf4,outA, outB, alu_control,alu,status,J);

endmodule 

module clockGen(rst, clk, clock);
// output clock during execute phase
input clk,rst;
output [5:0] clock;


reg [5:0] clock;


always @(posedge clk, posedge rst)
 begin
  if (rst) clock[0] <=1'b1;
  else begin
  clock <= clock << 1;
  clock[0] <= clock[5];
  end
  
 end 
 
endmodule


module fetch (clk,rst,instruction,programme_counter,status,p,J);

input clk,rst ;   // conditonalJump set by last alu operation
output signed  [7:0] programme_counter;
output [23:0] instruction;
output p,J;
input [7:0] status;

reg signed [7:0]  programme_counter;
reg [23:0] instruction;

reg [23:0] ProgMemory [0:31];
reg J;
reg pass;
//assign status = {1'b0,1'b0,1'b0, G,L,S,O,Z};  
wire Z,L,G,O,S;

assign Z = status[0];
assign G = status[4];
assign L = status[3];
assign p =pass;

parameter JUMP =4'hA, JG = 4'hC, JZ=4'hB, JL = 4'hD;

initial begin
      $readmemh("instructTest.txt",ProgMemory);   // preload instructions
      end

always @(posedge clk,posedge rst)
begin
   if (rst==1)
   //
        begin
           programme_counter <=5'd0;
           instruction = ProgMemory[programme_counter];  // 1st instruction
           pass = 1'b0;
         end
         
         else 
           begin
              // Blocking statement here because the current instruction needs to be loaded before case
              instruction = ProgMemory[programme_counter];  // only 32 locations in prog memory     
              J= 1'b0;  // clear any previous jumps
              
// jumps 
/*
For unconditional jumps the programme counter is just incremented, If theres is a conditional jump then an arithmetical
comparison has to be made and jump  if true else goto to next instruction.  For the latter a two pass approach is taken
For the first pass the programme counter is not incremented and in the second pass the the pc is modified to jump over the
unconditional jump to the next piece of code else it jumps back to test the condition again.  In looping code such as that code
required for 'for' or 'while' statements a jump returns the pc for next itieration. Only when the condition is met does it jump out the
the current programme loop.  In a possible branch operation the pc is modified by different amounts i.e. if true programme goes to one location 
if false it goes to a different location.
              
*/
               case (instruction[23:20])
                  JUMP  : begin    // uncondtional jump 
                            programme_counter <= programme_counter + instruction[19:12];   // this has be signed arithmetic 
                           J=1'b1;         
                          end   
                    JZ  :   begin
                            J=1'b1;
                            if (pass)
                              begin
                              if (Z)   // compares Rx with Ry or decremnent Rx
                               begin
                                   programme_counter <= programme_counter + instruction[19:12]; //jump over the unconditional jump
                                   J=1'b0;
                                   pass = 1'b0;
                                 end 
                                   else programme_counter <= programme_counter + 8'd1;   // this has to happen only on the second pass 
                       
                              end
                                else 
                                    begin
                                     
                                     pass = 1'b1;
                                     // programme_counter <= programme_counter - 8'd1;// programme counter not incremented but modified
                                     end

                              end
                    
                    JG  :    begin                                     
                             J=1'b1;
                             if (pass)
                                 begin
                                   if (G)   // compares Rx with Ry or decremnent Rx
                                     begin
                                       programme_counter <= programme_counter + instruction[19:12]; //jump over the unconditional jump
                                       J=1'b0;
                                       pass = 1'b0;
                                     end 
                                   else programme_counter <= programme_counter + 8'd1;   // this has to happen only on the second pass                       
                                end
                                else // first pass
                                    begin
                                     pass = 1'b1;
                                     // programme_counter <= programme_counter - 8'd1;// programme counter not incremented but modified
                                     end
                              end
                    JL  :    begin                                 
		                                  J=1'b1;
		                                  if (pass)
		                                      begin
		                                        if (L)   // compares Rx with Ry or decremnent Rx
		                                          begin
		                                            programme_counter <= programme_counter + instruction[19:12]; //jump over the unconditional jump
		                                            J=1'b0;
		                                            pass = 1'b0;
		                                          end 
		                                        else programme_counter <= programme_counter + 8'd1;   // this has to happen only on the second pass                       
		                                     end
		                                     else // first pass
		                                         begin
		                                          pass = 1'b1;
		                                          // programme_counter <= programme_counter - 8'd1;// programme counter not incremented but modified
		                                          end
                              end
                    default : begin
                               programme_counter <= programme_counter + 8'd1;
                                pass <= 1'b0;
                              end
               endcase
           end
 end
endmodule 


module decode (clk,instruction,WA,RA,regDat,DA,RegOp,rNWrD,operation ) ;
input clk;
input [23:0] instruction;
output [2:0] WA,RA;
output [3:0] DA;
output RegOp,rNWrD,regDat;
//input  J;  // do not load instruction is J = 1
output [3:0] operation;

reg RegOp,regDat,rNWrD;
reg [2:0] WA,RA;
reg [3:0] DA,operation;

   always @(posedge clk)   // decode
     begin              
          //IIII      JWWW       Reg/Data RRR    DDDD  RegOpRd/Wd IOen  AAAA
                         // 23..20   19..16        15..12       11..8   7..4       3..0
       //operation <= instruction[23:20];
        
            operation <= instruction[23:20];
            WA <=  instruction[18:16];   // write address
            RA <=  instruction[14:12];   // read address
            regDat <= instruction[15];
            DA <= instruction[11:8];
            RegOp <= instruction[6];   // set write for alu and load operations
            rNWrD <= instruction[5];
                            // IOen <= instruction[4];     not used                  
          
     end
endmodule
// make these as modules

module execute(clk,operation, alu_control);
input clk;
// output [5:0]  programme_counter;
input [3:0] operation;
output [3:0] alu_control;
reg [5:0] programme_counter;
reg [3:0] alu_control;
reg noWrite;

parameter LD = 4'd1, ADD=4'd2,SUB=4'd3, INC=4'd4,DEC=4'd5, COP = 4'd6, MUL = 4'd7,NOP =4'd0, AND =4'h8, XOR = 4'h9, JUMP =4'hA,JG = 4'hC, JZ=4'hB, JL=4'hD;
always @(posedge clk)  // execute
     begin
//       executing <= 1'b1;                             
       case(operation)
                                   NOP : begin
                                         alu_control = NOP;  // no operation ;
                                           
                                         end
                                   LD  : begin                
                                           // no alu operation
                                         alu_control = NOP;   // required because B line provides the data source to the data registers but ALU should not operate
	                                       
                                         end
                                   ADD : begin               // Rp = Rp + Rq
                              
                                           alu_control = ADD;  // arithmetic add
										           
										      
                                         end 
                                   SUB :begin               // Rp = Rp - Rq
                                           alu_control = SUB;  // arithmetic subtract
										   
                                         end
                                   
                                   INC  :begin   // increment Rp by 1
                                           alu_control = INC;  // increment register by 1
										  
                                         end 
                                   DEC : begin   // decrement Rp by 1
                                          alu_control = DEC;  // decrement register by 1
								          
                                         end 
                                   MUL :  begin               // Rp = Rp * Rq
                                           alu_control = MUL;  // unsigned multiply
										  
                                          end
                                   COP : begin
                                          alu_control = COP;  // copy from source register to destination
										  
                                         end 
                                   AND : begin
	                                   alu_control = AND;  // copy from source register to destination					  
				         end 
				                                            
				   XOR : begin
		                         alu_control = XOR;  // copy from source register to destination					  
                                         end 
                                   JUMP :  begin
                                           // pass through
                                           alu_control = NOP;    // no operation  
                                           end 
// *** additional instruction
                                   JG   :   // jump if Output less then zero
                                            begin
                                              // compute the jump  by subtracting but don't alter registers ie no writes occur
                                              
                                            alu_control = NOP;     
                                            end 
                                   JZ   :   // jump if A == B pass through
                                            begin
                                              // jump if Z flag set
                                             alu_control = NOP;   
                                            end 
                                   JL   :   // jump if A< B pass through
												begin
											// jump if L flag set
												alu_control = NOP;   
												end 
                                   default : alu_control = NOP;       
                                   
              endcase
         end

endmodule




module registers (clk1,clk2,regDat, aluIn,dataIn,wrAdd,readAdd1,readAdd2,RegOp,outAreg, outBreg);
// rdNwrt line superfluous, write occurs on clk1 edge
// J line is superfluous it is register Activity that allows writing
input [2:0] wrAdd,readAdd1,readAdd2;
input clk1,clk2,regDat,RegOp;
input [8:0] dataIn;
input [8:0] aluIn;
output [8:0] outAreg,outBreg;
reg[8:0] outAreg,outBreg;
// alu requires two inputs 
reg [8:0] regFile1 [0:7];
reg [8:0] regFile2 [0:7];
// wire RegAct;
// assign RegAct = ~J & RegOp;  // this condition has be to true for any register operation  

// to provent writing to a register during a jump the J gats

always @(posedge clk1)
  begin
 // if (executing)
  if (RegOp )  // RegAct 
    begin
     outAreg <= regFile1[readAdd1];   // these are presented to the ALU
     outBreg <= regFile2[readAdd2];
    end
     else 
       begin 
        outAreg <= 8'h0;
        outBreg <= 8'h0;
       end
  end   
//  This must be gated with RegOp to prevent writting to register at other times
always @(posedge clk2)
 begin
 if (RegOp)  
  begin
   if (regDat)
      begin
       regFile1[wrAdd] = aluIn;
       regFile2[wrAdd] = aluIn;
      end
       else 
          begin
           regFile1[wrAdd] = dataIn;
           regFile2[wrAdd] = dataIn;
          
         end
   end
 end

endmodule






module dataRegisters(clk,dataIn, dataOut, DA, RdNwrt,IOrequest);
// IOEn results  
input clk,RdNwrt,IOrequest;
input [8:0] dataIn;
output [8:0] dataOut;
input [3:0] DA;
//output IOen;   // enables Port IO


// tristate when IO required active low
assign dataOut = (IOen) ? dataOutput: 9'hZZZ; 

reg IOen;  
reg [8:0] dataOutput;
reg [8:0] regFile [0:15];

initial $readmemh("loadData.txt",regFile);   // preload data

always @(posedge clk)
 begin
   if (RdNwrt)   // reading
       begin
        if (IOrequest)
              begin 
               IOen = 1'b0; // in the case of  port read data is IO port data written direct to a register
               
              end
              else 
              begin
                  IOen = 1'b1;  
                  dataOutput = regFile[DA];
              end
       end 
      else 
      begin   // writing      
       if (IOrequest)              // 
          begin
           IOen = 1'b1; 
           dataOutput = dataIn;   // pass through to register file
          end 
          else
           begin 
           IOen = 1'b0;            
          end
       regFile[DA] = dataIn;       // write data to DA address or IO port
      end

 end 
 
 
endmodule
 
 module dataPort(portIO, dataBus, IOaddress, RdNwrt,IOrequest);
 
 input RdNwrt;
 input [3:0] IOaddress;
 inout [8:0] dataBus;
 inout [8:0] portIO;
 output IOrequest;
 //reg IOrequest;

 wire IO;
 assign IOrequest = & IOaddress;
 assign IO = & IOaddress;  // IO at data address 0xF
 assign control1 =IO & RdNwrt;  // writing data to port 
 assign control2 =IO & ~RdNwrt;

  // input to data port
 assign dataBus = (control1) ? portIO : 9'hZZZ ; 
 // output to data port
 assign portIO = (control2) ? dataBus: 9'hZZZ ;

 endmodule

