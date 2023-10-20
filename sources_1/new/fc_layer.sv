`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Edison Lam
// 
// Create Date: 24.04.2023 18:08:00
// Design Name: 
// Module Name: stolic_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// systolic array, used for matrix multiplication within layers and hidden layers to avoid fan-out and allows for pipelining
// 
// Dependencies: 
// 
// Revision:
// Revision 1.0
// Additional Comments:
//  Completed on the 27/04/2023
// 
//////////////////////////////////////////////////////////////////////////////////



/*
How things operate:
assuming you have matrix a * b, where a has m x n dimensions and b has n x p (rows x column)
m is the number of input images (height) but does not matter for this function as function will constantly output while in_valid (i am assuming it will be 1)
n is the number of inputs and their corresponding weights
p is the number of nerves within that layer

this module first loads n weights into their corresponding block and then turns on out_ready
the input of this module should be the diagonals of the matrix a and the output is the diagonals of the matrix c, 
    meaning these arrays can be linked up to one another to simulate each layer
the input is transposed and then inputted into the array
i.e if a was:
[00, 01, 02, 03]
[10, 11, 12, 13]
[20, 21, 22, 23]
[30, 31, 32, 33]

in_data needs to be
[00, --, --, --]
[10, 01, --, --]
[20, 11, 02, --]
[30, 21, 12, 03]
[--, 31, 22, 13]
[--, --, 32, 23]
[--, --, --, 33]


module takes m + n + p cycles to complete 
*/

// Module reads weights on reset and reads on every posedge after that, loads in once NumOfInputs cycles have occurred (including reset cycle)
// M_W_BitSize (i.e. Max Weight Bitsize) is there to save resources incase the memory isn't stored like the data
// fc_layer #(.BitSize(BitSize), .M_W_BitSize(), .Weight_BitSize(Weight_BitSize), .NumOfInputs(NumOfInputs), .NumOfNerves(NumOfNerves)) 
//         layer1 (
//             .clk(), .res_n(), .in_start(), .in_valid(), .in_data(), .in_weights(), 
//             .in_partial_sum(), .out_ready(), .out_valid(), .out_done(), 
//             .out_start(), .out_data());
module fc_layer #(BitSize = 8, M_W_BitSize = 8, Weight_BitSize = 8, NumOfInputs = 2, NumOfNerves = 8, DepthIn = 32, DepthOut = 2)
    (
        input                                   clk,
        input                                   res_n,
        input                                   en_l_b,
        input                                   in_start,           // signals when out_done and out_valid should stop, hold start for 1 cycle per height (m)
        input                                   in_valid,           // should always be on unless blockage
        input [NumOfInputs-1:0][BitSize-1:0]         in_data,            // (assuming m = 1)
        input [NumOfNerves-1:0][M_W_BitSize-1:0]     in_weights,         // actual value can be stored based on Weight_BitSize
        input [NumOfNerves-1:0][BitSize-1:0]         in_partial_sum,     // some can have biases

        output logic                                    out_valid,
        output logic                                    out_start,
        output logic                                    out_done,
        output logic [NumOfNerves/DepthOut-1:0][BitSize-1:0]     out_data
    );

    logic out_done_sys;
    logic out_start_sys;
    logic out_valid_sys;
    logic [NumOfNerves-1:0][BitSize-1:0] out_data_sys;

    logic in_start_sum;
    logic in_valid_sum;
    logic [NumOfNerves-1:0][BitSize-1:0] in_data_sum;

    logic out_start_sum;
    logic out_valid_sum;
    logic [BitSize-1:0] out_data_sum;

    // add pipeline regs between layers
    always_ff @(posedge clk) begin
        out_done        <= out_done_sys;
        in_start_sum    <= out_start_sys;
        in_valid_sum    <= out_valid_sys;
        in_data_sum     <= out_data_sys;
    end

    systolic_array #(.BitSize(BitSize), .Weight_BitSize(Weight_BitSize), .M_W_BitSize(M_W_BitSize), .NumOfInputs(NumOfInputs), 
        .NumOfNerves(NumOfNerves), .DepthIn(DepthIn)) systolic_array_multiplier (
            .clk(clk), .res_n(res_n), .in_valid(in_valid), .in_start(in_start), .in_data(in_data), 
            .in_weights(in_weights), .in_partial_sum(in_partial_sum), .en_l_b(en_l_b), 
            .out_start(out_start_sys), .out_valid(out_valid_sys), .out_done(out_done_sys), .out_data(out_data_sys));

    sys_sum #(.BitSize(BitSize), .NumOfNerves(NumOfNerves), .DepthIn(DepthIn)) systolic_sum (
        .clk(clk), .res_n(res_n), .in_valid(in_valid_sum), .in_start(in_start_sum), .in_data(in_data_sum),  
        .out_start(out_start_sum), .out_valid(out_valid_sum), .out_data(out_data_sum)
    );

    sys_stacker #(.BitSize(BitSize), .NumOfNerves(NumOfNerves), .DepthOut(DepthOut)) systolic_stacker (
        .clk(clk), .res_n(res_n), .in_valid(out_valid_sum), .in_start(out_start_sum), .in_data(out_data_sum),  
        .out_start(out_start), .out_valid(out_valid), .out_data(out_data)
    );


    
endmodule
