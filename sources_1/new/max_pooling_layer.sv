`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2023 14:39:05
// Design Name: 
// Module Name: max_pooling_layer
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

// utilises max pooling module to shrink down a whole input image based pooling size
// assumes ImageWidth % N = 0
// also assumes input will be streamed in similar to convolution stage
// latency of 1 because when testing for 0, it does not run as expected
// max_pooling_layer #(.N(), .ImageWidth(), .BitSize()) pooling_layer (.clk(), .res_n(), .in_valid(), .in_data(), .out_ready(), .out_valid(), .out_data());
module max_pooling_layer #(N = 2, ImageWidth = 4, BitSize = 32, Stride = 2)
    (
        input                       clk,
        input                       res_n,
        input                       in_valid,         // enable

        input [BitSize-1:0]         in_data,

        output logic                out_ready,          // don't think this is necessary as padding is not an issue and there are no wasted cycles
                                                        // only when out_ready is high, data should be given
        output logic                out_done,
        output logic                out_valid,
        output logic [BitSize-1:0]  out_data
    );

    localparam StreamSize = 	(ImageWidth)*(N-1)+N; // no padding required
  
  	logic [StreamSize-1:0][BitSize-1:0] data_stream_r;
    logic [StreamSize-1:0][BitSize-1:0] data_stream_c;
  	integer 					image_pos_r;
  	integer						image_pos_c;
    integer                     image_row_r;
    integer                     image_row_c;
	logic [N-1:0][N-1:0][BitSize-1:0]	pooling_data;


	genvar i;
	genvar j;
	generate;
		for (i = 0; i < N; i = i + 1) begin
			for (j = 0; j < N; j = j + 1) begin
				assign pooling_data[i][j] = data_stream_r[i * ImageWidth + j]; // change to data_stream_c for 0 latency
			end
		end
	endgenerate

    always@(posedge clk) begin
    	if(!res_n)
      	begin
        	image_pos_r <= 0;
			data_stream_r <= 'b0;
            image_row_r <= 0;
      	end
    	else
      	begin
        	image_pos_r <= image_pos_c;
            image_row_r <= image_row_c;
            data_stream_r <= data_stream_c;
        end
  	end

    assign out_valid = (image_pos_c >= StreamSize && (image_pos_c % Stride == 0) && (image_row_c % Stride == 0)) && in_valid;  // change to c for 0 latency
    
    assign out_done = (image_pos_r>=(StreamSize+ImageWidth/2) & image_row_r>=(ImageWidth/2))?1:0;

    always_comb begin
        out_ready = 1;
        data_stream_c = data_stream_r;
        image_pos_c = image_pos_r;
        image_row_c = image_row_r;

        if (in_valid) begin         // store values
            image_pos_c = image_pos_r + 1; 
            data_stream_c = {data_stream_r[StreamSize-2:0], in_data};
            if (image_pos_c - ImageWidth >= StreamSize) begin // means a whole row has been passed
                image_pos_c = StreamSize;                       // assumes imagewidth is divisible by stride
                image_row_c = image_row_r + 1;
            end
            // out_ready = 1;
        end


    end

    max_pooling #(.N(N), .BitSize(BitSize)) pooling_func (.in_data(pooling_data), .out_data(out_data));


endmodule
