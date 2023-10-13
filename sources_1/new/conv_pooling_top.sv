`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Additional Comments:
// 
//One Convolution stage with 3 kernels that feeds into 3 convoltuion stage each
//with a variable number of kernels and kernel bit size
//The Number of Kernels for each layer 2 convolution must be equal to or greater
//than or equal to the layer 2 cycles per pixel
//
//////////////////////////////////////////////////////////////////////////////////

module conv_pooling_top #(N = 3, BitSize=32, ImageWidth = 8, L1CyclesPerPixel = 1, Stride = 2,
        C1NumberOfK = 4, C2NumberOfK = 4, C2ProcessingElements = 2,
        C1KernelBitSize = 4, C2KernelBitSize = 4,// C3KernelBitSize = 2,
        [C1KernelBitSize*(N*N)-1:0] C1kernel [C1NumberOfK-1:0] = {'0,'0,'0,'0},
        [C2KernelBitSize*(N*N)-1:0] C2kernel [C2NumberOfK-1:0] = {'0,'0,'0,'0})
        // [C3KernelBitSize*(N*N)-1:0] C3kernel [C3NumberOfK-1:0] = {'0,'0,'0,'0})
	(
    		input 						                        clk,
            input                                               res_n,
        	input 						                        in_valid,
            input [BitSize-1:0] 	                            in_data,
            
            output logic                                        out_ready,

            output logic [C2NumberOfK-1:0]                      out_valid,
            output logic [C2ProcessingElements-1:0][BitSize-1:0] 	    out_data
    );

    //localparam C1NumberOfK = 3;
    localparam L2CyclesPerPixel = L1CyclesPerPixel*Stride**2;
    localparam L2ImageWidth = ImageWidth/Stride;
    localparam ProcessingElements = 2;

    logic                   C2_buffer_done;
    logic                   C2_pooling_done;
    logic                   C2_rst;
    logic                   mem_image_done;

    logic[C1NumberOfK-1:0]                          C1_out_valid;
    logic[ProcessingElements-1:0] [BitSize-1:0] 	C1_out_data;

    logic                   mem_1_out_valid;
    logic [BitSize-1:0]     mem_1_out_data;

    
    assign  C2_rst = !(!res_n|C2_pooling_done);

    //First convolution stage with 3 kernels
    conv_pooling_layer #(.N (N), .BitSize(BitSize), .ImageWidth(ImageWidth), .NumberOfK(C1NumberOfK), 
        .KernelBitSize(C1KernelBitSize), .CyclesPerPixel(L1CyclesPerPixel), .Stride(Stride),
        .ProcessingElements(2), .kernel(C1kernel)) C1
		(
    		.clk(clk),
            .res_n(res_n),
        	.in_valid(in_valid),
            .in_data(in_data),
            .out_ready(out_ready),
        	.out_valid(C1_out_valid),
            .out_data(C1_out_data)
    );

    mem_module #(.NumberOfK(C1NumberOfK), .BitSize(BitSize), .ImageWidth(L2ImageWidth)) mem_1
        (
            .clk(clk),
            .res_n(res_n),
            .pooling_done(C2_pooling_done),
            .in_valid(C1_out_valid),
            .in_data(C1_out_data),
            .out_data(mem_1_out_data),  
            .out_valid(mem_1_out_valid),  
            .image_done(mem_image_done)
        );


    conv_pooling_layer #(.N (N), .BitSize(BitSize), .ImageWidth(L2ImageWidth), .NumberOfK(C2NumberOfK), 
        .KernelBitSize(C2KernelBitSize), .CyclesPerPixel(L1CyclesPerPixel), .Stride(Stride),
        .ProcessingElements(C2ProcessingElements), .kernel(C2kernel)) C2
		(
    		.clk(clk),
            .res_n(C2_rst),
        	.in_valid(mem_1_out_valid),
            .in_data(mem_1_out_data),
            .out_ready(),
        	.out_valid(out_valid),
            .out_data(out_data),
            .buffer_done(C2_buffer_done),
            .pooling_done(C2_pooling_done)
    );



endmodule