`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.03.2023 14:56:36
// Design Name: 
// Module Name: max_pooling
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

// does not work for N = 1
// can probably be upgraded by hardcoding the interactions for 3x3 inputs and so on (result found in 1 cycle)
// can probably be sped up by comparing more simultaneously
// max_pooling #(.N(), .BitSize()) test_max_pooling (.in_data(), .out_data());
module max_pooling #(N = 3, BitSize = 8) (
    input signed [BitSize*(N*N)-1:0] in_data,
    output logic [BitSize-1:0] out_data
    );
    localparam int size = N*N;
    // localparam int depth = $clog2(size); // finding depth based on size of in_data
    
    // separating in_data into easier chunks
    wire [N*N-1:0][BitSize-1:0] i_data_layers;
    assign i_data_layers = in_data;
    
    integer i;
        
    always_comb begin
        out_data = BitSize'('b0);
        // scan through all the in_data and find max
        for (i = 0; i < size; i = i + 1) begin
//            $display("%d: %d", i, $signed(i_data_layers[i]));
            out_data = ($signed(out_data) < $signed(i_data_layers[i])) ? i_data_layers[i] :  out_data;
        end
    end
    
endmodule
