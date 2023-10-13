`timescale 1ns / 1ps

module switch #(NumberOfK = 4, CyclesPerPixel = 2)
		(
    		input 							clk,
            input                           res_n,
        	input 							in_valid,     // enable   
        	output logic[NumberOfK-1:0]     out_valid
      	
    );

	localparam ProcessingElements = (NumberOfK+CyclesPerPixel-1)/CyclesPerPixel;

    integer count_c;
    integer count_r;

    always_comb begin
        count_c     = count_r;
        out_valid   = '0;
        if(in_valid)
        begin
            out_valid[count_c+:ProcessingElements] = {ProcessingElements{1'b1}};
            count_c = (count_c + ProcessingElements) % NumberOfK;
        end
    end

    always_ff@(posedge clk) begin
        if(!res_n) begin
            count_r     <= '0;
        end
        else
        begin
            count_r     <= count_c;
        end
    end

endmodule