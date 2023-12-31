`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2023 22:14:21
// Design Name: 
// Module Name: convolution_stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module conv_pooling_layer #(N = 3, BitSize=8, ImageWidth = 16, NumberOfK = 8,
 KernelBitSize = 1, ProcessingElements = 2, 
                            CyclesPerPixel = NumberOfK/ProcessingElements, Stride = 2,
                            [KernelBitSize*(N*N)-1:0] kernel [NumberOfK-1:0] = {'0,'0,'0,'0,'0,'0,'0,'0})
		(
    		input 						clk,
            input                       res_n,
        	input 						in_valid,     // enable
            // input [NumberOfK-1:0][KernelBitSize*(N*N)-1:0] kernel,   
            input [BitSize-1:0] 	    in_data,

        	output logic                buffer_done,
            output logic                pooling_done,
            output logic                out_ready,
            output logic[NumberOfK-1:0]     out_valid,
            output logic [ProcessingElements-1:0][BitSize-1:0] 	    out_data
      	
    );

    //parameter [KernelBitSize*(N*N)-1:0] kernel [NumberOfK-1:0] = {'0,'0,'0,'0};

    //localparam ProcessingElements = NumberOfK/CyclesPerPixel;

    logic [(N*N)*BitSize-1:0] 	        buffer_out;
    logic                               buffer_valid;

    logic                               conv_valid;
    logic [NumberOfK-1:0][BitSize-1:0] 	conv_out;

    logic [NumberOfK-1:0]               switch_valid;
    logic [NumberOfK-1:0]               pooling_done_arr;

    logic                               conv_valid_r;
    logic [NumberOfK-1:0][BitSize-1:0] 	conv_out_r;

    logic [NumberOfK-1:0][BitSize-1:0]   pooling_temp;


    assign pooling_done = (pooling_done_arr=={NumberOfK{1'b1}})?1:0;



    convolution_buffer #(.N(N),  .BitSize(BitSize), .ImageWidth(ImageWidth)) conv_buffer
	(
        .clk(clk),
        .res_n(res_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_ready(out_ready),
        .out_valid(buffer_valid),
        .out_data(buffer_out),
        .out_done(buffer_done)
    );

    convolution_stage #(.NumberOfK(NumberOfK), .N(N), .BitSize(BitSize), 
        .KernelBitSize(KernelBitSize), .ImageWidth(ImageWidth), .ProcessingElements(ProcessingElements), .kernel(kernel)) conv_stage
	(
    	.clk(clk),
        .res_n(res_n),
        .in_valid(buffer_valid),
        .in_data(buffer_out),      
      	.out_ready(),
        .out_valid(conv_valid),
        .out_data(conv_out)	
    );

    switch #(.NumberOfK(NumberOfK), .CyclesPerPixel(CyclesPerPixel)) conv_switch
	(
    	.clk(clk),
        .res_n(res_n),
        .in_valid(conv_valid_r),  
        .out_valid(switch_valid)    	
    );

    genvar i;
    generate;
        for (i = 0; i<NumberOfK; i=i+1) begin
            max_pooling_layer #(.N(Stride), .ImageWidth(ImageWidth), .BitSize(BitSize), .Stride(Stride)) pooling_layer
            (
                .clk(clk),
                .res_n(res_n),
                .in_valid(switch_valid[i]),
                .in_data(conv_out_r[i%ProcessingElements]),
                .out_ready(),
                .out_done(pooling_done_arr[i]),
                .out_valid(out_valid[i]),
                .out_data(pooling_temp[i])
            );
        end
    endgenerate

    integer j;
    always_comb
    begin
        out_data = '0;
        for(j = 0; (j < NumberOfK); j = j + 1) begin
            out_data[j%ProcessingElements] = out_data[j%ProcessingElements]|out_valid[j]*pooling_temp[j];
        end
    end


    always_ff@(posedge clk) begin
        conv_valid_r    <= conv_valid;
        conv_out_r      <= conv_out;
  	end


endmodule