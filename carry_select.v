`timescale 1ns / 1ps

module carry_select #(
    parameter   ADDER_WIDTH = 32,
    parameter   NUMBER_OF_BLOCKS = 6,
    parameter   BLOCK_WIDTH = ADDER_WIDTH / NUMBER_OF_BLOCKS,
    parameter   FIRST_BLOCK_WIDTH = ADDER_WIDTH % NUMBER_OF_BLOCKS
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);

	wire [NUMBER_OF_BLOCKS-1:0] w0Carry, w1Carry, w0Finished, w1Finished;
	reg [NUMBER_OF_BLOCKS-1:0] rCarry, rFinished;
	
	reg [ADDER_WIDTH-1:0]  rSum;
	wire [BLOCK_WIDTH-1:0]  w1Sum [NUMBER_OF_BLOCKS-1:0];
	wire [BLOCK_WIDTH-1:0]  w0Sum [NUMBER_OF_BLOCKS-1:0];
	
    wire [FIRST_BLOCK_WIDTH-1:0] wSumFirst;
    wire  wCarryFirst, wFinishedFirst;

    // variable to control for loop
    genvar i;


//first ripple carry adder accepts remainder ADDER_WIDTH/(NUMBER_OF_BLOCKS-1) bits of input
    ripple_carry_adder_Nb #( .ADDER_WIDTH(FIRST_BLOCK_WIDTH) ) 
    ripple_carry_init   (
        .iA( iA[FIRST_BLOCK_WIDTH-1:0] ), 
        .iB( iB[FIRST_BLOCK_WIDTH-1:0] ),
        .iCarry( iCarry ),
        .oSum(wSumFirst),
        .oCarry(wCarryFirst),
        .oFinished(wFinishedFirst)
      );

//adders for both carry cases
generate
    for (i=1; i<NUMBER_OF_BLOCKS+1; i=i+1)  begin
        ripple_carry_adder_Nb #( .ADDER_WIDTH(BLOCK_WIDTH) ) 
            ripple_carry_0_inst (
                    .iA(iA[(BLOCK_WIDTH)*i+FIRST_BLOCK_WIDTH:(BLOCK_WIDTH)*(i-1)+FIRST_BLOCK_WIDTH]), 
                    .iB(iB[(BLOCK_WIDTH)*i+FIRST_BLOCK_WIDTH:(BLOCK_WIDTH)*(i-1)+FIRST_BLOCK_WIDTH]), 
                    .iCarry(0), 
                    .oSum(w0Sum[i]),
                    .oCarry(w0Carry[i]), 
                    .oFinished(w0Finished[i])
                );
        ripple_carry_adder_Nb #( .ADDER_WIDTH(BLOCK_WIDTH) ) 
            ripple_carry_1_inst (
                    .iA(iA[(BLOCK_WIDTH)*i+FIRST_BLOCK_WIDTH:(BLOCK_WIDTH)*(i-1)+FIRST_BLOCK_WIDTH]), 
                    .iB(iB[(BLOCK_WIDTH)*i+FIRST_BLOCK_WIDTH:(BLOCK_WIDTH)*(i-1)+FIRST_BLOCK_WIDTH]), 
                    .iCarry(1), 
                    .oSum(w1Sum[i]), 
                    .oCarry(w1Carry[i]), 
                    .oFinished(w1Finished[i])
                );
    end 
endgenerate

integer j; //previous block that finished

always @(*)
    begin
        for (j=0; j<NUMBER_OF_BLOCKS; j=j+1) 
        begin
        $display("block number: %d", j);
            if (j==0) 
            begin
                if (!wFinishedFirst==1) j = j-1;
                else
                begin
                    $display("sum: %d, carry: %d", wSumFirst, wCarryFirst);
                    rCarry[j] = wCarryFirst;
                    rFinished[j] = 1;
                    rSum = {wSumFirst, rSum[ADDER_WIDTH-1:ADDER_WIDTH-FIRST_BLOCK_WIDTH]};
                end
            end
            else 
            begin
                if (!(rFinished[j-1]==1 && w0Finished[j]==1 && w1Finished[j]==1)) j = j-1;
                else
                begin
                    if (rCarry[j-1]==1) 
                    begin
                        $display("carry was 1");
                        rCarry[j] = w1Carry[j];
                        rFinished[j] = 1;
                        rSum = {w1Sum[j], rSum[ADDER_WIDTH-1:BLOCK_WIDTH]}; //shift register
                    end
                    else 
                    begin
                        $display("carry was 0");
                        rCarry[j] = w0Carry[j];
                        rFinished[j] = 1;
                        rSum = {w0Sum[j], rSum[ADDER_WIDTH-1:BLOCK_WIDTH]}; //shift register
                    end
                    $display("sum: %d, carry: %d", rSum[ADDER_WIDTH-1:ADDER_WIDTH-BLOCK_WIDTH], rCarry[j]);
                end
            end
        end
    end

    assign oCarry = rCarry[ADDER_WIDTH-1];
    assign oSum = rSum;

endmodule
