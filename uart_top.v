`timescale 1ns / 1ps

module uart_top #(
    parameter   OPERAND_WIDTH = 512,
    parameter   ADDER_WIDTH   = 32,
    parameter   NBYTES        = OPERAND_WIDTH / 8,    
    // values for the UART (in case we want to change them)
    parameter   CLK_FREQ      = 125_000_000,
    parameter   BAUD_RATE     = 115_200
)  
(
    input   wire   iClk, iRst,
    input   wire   iRx,
    output  wire   oTx
);
  
  // Buffer to exchange data between Pynq-Z2 and laptop
  reg [NBYTES*8-1:0] rA;
  reg [NBYTES*8-1:0] rB;
  
  // State definition  
  localparam s_IDLE         = 3'b000;
  localparam s_WAIT_RX_A    = 3'b001;
  localparam s_WAIT_RX_B    = 3'b101;
  localparam s_ADD          = 3'b110;
  localparam s_TX           = 3'b010;
  localparam s_WAIT_TX      = 3'b011;
  localparam s_DONE         = 3'b100;
   
  // Declare all variables needed for the finite state machine 
  // -> the FSM state
  reg [2:0]   rFSM;  
  
  // Connection to UART TX (inputs = registers, outputs = wires)
  reg         rTxStart;
  reg [7:0]   rTxByte;
  
  wire        wTxBusy;
  wire        wTxDone;
  
  // Connection to UART RX
  wire        wRxDone;
  wire [7:0]  wRxByte;
  
  // Connection to adder
  reg       rAddStart;
  wire [NBYTES*8:0]   wRes;
  reg  [(NBYTES+1)*8-1:0]   rRes;
  wire      wAddDone;
      
  uart_tx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_TX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(oTx),
     .oTxBusy(wTxBusy),
     .oTxDone(wTxDone)
     );
     
  uart_rx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_RX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iRxSerial(iRx),
     .oRxByte(wRxByte),
     .oRxDone(wRxDone)
     );
     
 mp_adder #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH))
 MP_ADDER_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iStart(rAddStart),
     .iOpA(rA),
     .iOpB(rB),
     .oRes(wRes),
     .oDone(wAddDone)
     );
     
  reg [$clog2(NBYTES):0] rCnt;

    always @(posedge iClk)
  begin
  
  // reset all registers upon reset
  if (iRst == 1 ) 
    begin
      rFSM <= s_IDLE;
      rTxStart <= 0;
      rCnt <= 0;
      rTxByte <= 0;
      rA <= 0;
      rB <= 0;
    end 
  else 
    begin
      case (rFSM)
   
        s_IDLE :
          begin
            rFSM <= s_WAIT_RX_A;
            rTxStart <= 0;
            rCnt <= 0;
            rTxByte <= 0;
            rA <= 0;
            rB <= 0;
          end
          
        s_WAIT_RX_A :
          begin
          //buffer updated with bytes received by the module
            if (wRxDone==1)
              begin
                rA <= {rA[NBYTES*8-9:0],wRxByte};
                if (rCnt < NBYTES-1)
                  begin
                    rCnt <= rCnt + 1;
                    rFSM <= s_WAIT_RX_A;
                  end
                else
                  begin
                    rCnt <= 0;
                    rFSM <= s_WAIT_RX_B;
                  end
              end       
          end
          
       s_WAIT_RX_B :
          begin
          //buffer updated with bytes received by the module
            if (wRxDone==1)
              begin
                rB <= {rB[NBYTES*8-9:0],wRxByte};
                if (rCnt < NBYTES-1)
                  begin
                    rCnt <= rCnt + 1;
                    rFSM <= s_WAIT_RX_B;
                  end
                else
                  begin
                    rAddStart <= 1;
                    rCnt <= 0;
                    rFSM <= s_ADD;
                  end
              end       
          end
          
            
        s_ADD:
            begin
                rAddStart <= 0; // Ensure the start signal is deasserted
                if (wAddDone) begin
                    rRes <= {7'b0000000, wRes}; // Capture adder result into register
                    rFSM <= s_TX; // Proceed to transmission
                end else begin
                    rFSM <= s_ADD; // Wait until addition is done
                end
            end
                 
        s_TX :
          begin
            if ( (rCnt < NBYTES+1) && (wTxBusy ==0) ) 
              begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 1; 
                rTxByte <= rRes[(NBYTES+1)*8-1:(NBYTES+1)*8-8];            // we send the uppermost byte
                rRes <= {rRes[(NBYTES+1)*8-9:0] , 8'b0000_0000};    // we shift from right to left
                rCnt <= rCnt + 1;
              end 
            else 
              begin
                rFSM <= s_DONE;
                rTxByte <= 0;
                rCnt <= 0;
              end
            end 
            
            s_WAIT_TX :
              begin
                rTxStart <= 0;
                if (wTxDone) begin
                  rFSM <= s_TX;
                end else begin
                  rFSM <= s_WAIT_TX;
                  rTxStart <= 0;                   
                end
              end 
              
            s_DONE :
              begin
                rFSM <= s_IDLE;
              end 

            default :
              rFSM <= s_IDLE;
          endcase
      end
  end       
    
endmodule