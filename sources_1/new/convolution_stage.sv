`timescale 1ns / 1ps

// note: N is the size of the kernel - might make it during run-time rather than compilation
// Some features to add after: - stride steps, increased number of data loaded in at once (parameterised)
// convolution_stage #(.NumberOfK(), .N(), .BitSize(), .KernelBitSize(), .ImageWidth()) conv_s (.clk(), .res_n(), .in_valid(), .kernel(), .in_data(), .out_ready(), .out_valid(), .out_data());
module convolution_stage #(NumberOfK = 8, N = 3, BitSize=8, KernelBitSize = 1, ImageWidth = 16, 
							ProcessingElements = 1, CyclesPerPixel = NumberOfK/ProcessingElements,
							[KernelBitSize*(N*N)-1:0] kernel [NumberOfK-1:0] = {'0,'0,'0,'0, '0,'0,'0,'0})
		(
    		input 							clk,
            input                           res_n,
        	input 							in_valid,     // enable
          	// input [NumberOfK-1:0][KernelBitSize*(N*N)-1:0] kernel,
          	input [(N*N)*BitSize-1:0] 			in_data,      
      		output logic 						out_ready,
        	output logic 						out_valid,
          	output logic [ProcessingElements-1:0][BitSize-1:0] 			out_data // Have to update to number of prtocessing elements  
      	
    );


	// Note number of '0's in default value must equal default num K
	//parameter [KernelBitSize*(N*N)-1:0] kernel [NumberOfK-1:0] = {'0,'0,'0,'0};


	localparam BufferSize 			= ImageWidth**2;

	logic [BufferSize-1:0] [(N*N)*BitSize-1:0] buffer_c;
	logic [BufferSize-1:0] [(N*N)*BitSize-1:0] buffer_r;

	integer buffer_count_c;
	integer buffer_count_r;

	integer cycle_count_c;
	integer cycle_count_r;


	//make sure output is lined up properly
	genvar i;
	generate;
		for (i = 0; (i < ProcessingElements); i = i + 1) begin
			 dot_NxN #(.N(N), .BitSize(BitSize), .KernelBitSize(KernelBitSize)) 
			 dot_product (.kernel(kernel[i+(cycle_count_c*ProcessingElements)]), .in_data(buffer_c[0]), .out_data(), .sum(out_data[i]));
		end
	endgenerate


  	always_comb
    begin
		buffer_c 		= buffer_r;
		buffer_count_c 	= buffer_count_r;
		cycle_count_c 	= cycle_count_r;
		cycle_count_c 	= cycle_count_c + 1;
		if(in_valid)
		begin
			// read into the correct count on the register
			buffer_count_c				= buffer_count_c + 1;
			buffer_c[buffer_count_c] 	= in_data;
		end
		// update cycle count and move through kernels, then shift out of buffer reduce buffer count
		if((cycle_count_c >= CyclesPerPixel) && (buffer_count_c > 0))
		begin
			cycle_count_c 			= 0;
			buffer_c = buffer_c 	>> (N*N)*BitSize;
			buffer_count_c 			= buffer_count_c - 1;
		end

		out_valid = 1'b0;
		if(cycle_count_c < CyclesPerPixel) begin
			out_valid = 1'b1;
		end
		out_ready = 1'b0;
		if(buffer_count_c < BufferSize) begin
			out_ready = 1'b1;
		end
    end


	always_ff@(posedge clk) begin
    	if(!res_n)
      	begin
			buffer_r <= '0;
			buffer_count_r <= '0;
			cycle_count_r <= CyclesPerPixel+1;
      	end
    	else
      	begin
        	buffer_r <= buffer_c;
			buffer_count_r <= buffer_count_c;
			cycle_count_r <= cycle_count_c;
        end
  	end

    
endmodule