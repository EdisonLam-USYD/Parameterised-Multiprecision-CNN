`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2023
// Design Name: 
// Module Name: convolution_buffer
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

// This stage is before the dot-product part as we can potentially reuse each dot-product module depending on pooling/strides
// It provides the convolution window image and accounts for padding
// requires a reset before each new input

// note: N is the size of the kernel, for this module, we assume that N is odd and therefore has a centrepoint
// Some features to add after: - stride steps

// convolution_buffer #(.NumberOfK(), .N(), .BitSize(), .ImageWidth()) conv_b 
// 				(.clk(), .res_n(), .in_valid(), .in_data(), .in_done(), .out_ready(), .out_valid(), .out_data(), .out_done());
module convolution_buffer #(N = 3, BitSize=32, ImageWidth = 4)
	(
		input 							clk,
		input                           res_n,
		input 							in_valid,     // enable

		input [BitSize-1:0] 			in_data,
		// input							in_done,		// needs to occur on last in_valid data, TODO
	
		output logic 						out_ready,
		output logic 						out_valid,
		output logic [(N*N)*BitSize-1:0] 	out_data,
		output logic 						out_done		// TODO ??
    );
  
  	localparam StreamSize 		= (ImageWidth)*(N-1)+(N);
	// padding conditions - when should we add padding based on the image position counter
	localparam PaddingCond_1 	= (N-1)/2;			// padding on the left
	localparam PaddingCond_2 	= ImageWidth-1;

  
  	logic [StreamSize-1:0][BitSize-1:0] data_stream_r;
  	logic [StreamSize-1:0][BitSize-1:0] data_stream_c;
	logic [N-1:0][N-1:0][BitSize-1:0] out_window_c;			// combinational version of out_data
	logic [N-1:0][N-1:0][BitSize-1:0] out_window_r;	

	assign out_data = out_window_c;
	// assign out_done = done_counter >= StreamSize;
	
  	integer 					image_pos_r;
  	integer						image_pos_c;
    integer                     image_row_r;
    integer                     image_row_c;

    
    logic [N-1:0][N-1:0][BitSize-1:0]s;
	logic [N-1:0][N-1:0][BitSize-1:0]next;
	logic [N-1:0][N-1:0][BitSize-1:0]next0;
	logic [N-1:0][N-1:0][BitSize-1:0]out_prev;

    	always_comb
	begin
        out_valid 		= 0;
		out_ready 		= 1;
		out_done		= 0;
    	image_pos_c 	= image_pos_r;
		image_row_c 	= image_row_r;
		data_stream_c 	= data_stream_r;

		out_window_c 	= out_window_r;
		// done_c = 0;

		if (image_row_r > PaddingCond_2 || (image_row_r == PaddingCond_2 && image_pos_r >= PaddingCond_2 - 1)) out_ready = 0;

		if (in_valid || !out_ready)
		begin
        	image_pos_c = (image_pos_r >= PaddingCond_2) ? 0 : image_pos_r + 1;
			image_row_c = (image_pos_r >= PaddingCond_2) ? image_row_r + 1: image_row_r;
			data_stream_c = (out_ready) ? {data_stream_r[StreamSize-2:0], in_data} : {data_stream_r[StreamSize-2:0], BitSize'(0)};

			// if (((image_pos_c >= PaddingCond_1 && image_row_c == PaddingCond_1) || image_row_c > PaddingCond_1) && done_counter < StreamSize)
			if ((image_pos_c >= PaddingCond_1 && image_row_c == PaddingCond_1) || image_row_c > PaddingCond_1)
			begin
				out_valid = 1;
				// out_valid = (!out_ready && ((image_row_c > PaddingCond_2 + PaddingCond_1) || (image_row_c == ImageWidth + PaddingCond_1 && image_pos_c < PaddingCond_1))) ? 0 : 1;
				if (!out_ready)
				begin
					if (image_row_c == ImageWidth + PaddingCond_1 && image_pos_c < PaddingCond_1) out_valid = 1;
					else if (image_row_c > PaddingCond_2 + PaddingCond_1) 
					begin
						out_valid = 0;
						out_done  = 1;
					end
				end
			
				if (image_pos_c == PaddingCond_1) // line is reset, padding should be added to the left, everything shifted up
				begin
					out_window_c = s;
				end
				else if (image_pos_c < PaddingCond_1) // padding on right is starting to be required
				begin
					out_window_c = next0;
				end
				else
				begin
					out_window_c = next;
				end
			end
			// else done_c = 1;
        end
		// if (!out_ready && image_row_c > PaddingCond_2 + PaddingCond_1) // auto reset
		// begin
		// 	out_valid = 0;
		// 	image_pos_c 	= PaddingCond_2;
		// 	image_row_c 	= -1;			
		// 	data_stream_c 	= 0;
		// 	out_window		= '0;
		// end
    end

  	always@(posedge clk) begin
    	if(!res_n)
      	begin
			image_pos_r 	<= PaddingCond_2;	// should be 0 on first input
			image_row_r 	<= -1;				// should be 0 on first input
			data_stream_r 	<= 0;
			out_prev 		<= '0;
			out_window_r	<= '0;
			// done_counter_r <= 0;
      	end
    	else
      	begin
        	image_pos_r 	<= image_pos_c;
			image_row_r 	<= image_row_c;
			data_stream_r 	<= data_stream_c;
			out_prev 		<= out_data;
			out_window_r 	<= out_window_c;
			// done_counter_r <= done_counter_c;
			// done <= (in_done || done) && !done_c;
        end
  	end


	genvar i;
	genvar j;
	generate
		if (N == 1) 
		begin
			assign s 		= data_stream_c;
			assign next 	= s;
			assign next0 	= s;
		end
		else
		begin
			for (i = 0; i < N; i = i + 1)
			begin
				for (j = 0; j < N; j = j + 1)
				begin
					assign s[i][j] 		= (j > PaddingCond_1) ? 0 : data_stream_c[i*ImageWidth + j];
					assign next[i][j] 	= (j != 0) ? out_prev[i][j-1] : data_stream_c[i*ImageWidth + j];
					assign next0[i][j] 	= (j == 0) ? 0 : out_prev[i][j-1];
				end
			end
		end
	endgenerate

endmodule