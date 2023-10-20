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
// systolic_array #(.BitSize(BitSize), .M_W_BitSize(), .Weight_BitSize(Weight_BitSize), .NumOfInputs(NumOfInputs), .NumOfNerves(NumOfNerves)) 
//         layer1 (.clk(), .res_n(), .in_start(), .in_valid(), .in_data(), .in_weights(), .in_partial_sum(), .out_ready(), .out_valid(), .out_done(), .out_start(), .out_data())
module systolic_array #(BitSize = 8, M_W_BitSize = 4, Weight_BitSize = 2, NumOfInputs = 2, NumOfNerves = 2, DepthIn = 1)
    (
        input                                   clk,
        input                                   res_n,
        // input                                   in_w_en,
        input                                   en_l_b,
        input                                   in_start,           // signals when out_done and out_valid should stop, hold start for 1 cycle per height (m)
        input                                   in_valid,           // should always be on unless blockage
        input [NumOfInputs*BitSize-1:0]         in_data,            // (assuming m = 1)
        input [NumOfNerves*M_W_BitSize-1:0]     in_weights,         // actual value can be stored based on Weight_BitSize
        input [NumOfNerves*BitSize-1:0]         in_partial_sum,     // some can have biases

        output logic                                    out_valid,
        output logic                                    out_start,
        output logic                                    out_done,
        output logic [NumOfNerves-1:0][BitSize-1:0]     out_data
    );

    // takes BlockSize cycles to load in all b values
    // logic en_l_b;
    // logic [$clog2(NumOfInputs)+1:0] counter_w;                          // counts the loading of the weights for each of the nerves (NumOfInputs times)

    logic [NumOfInputs-1:0][BitSize-1:0]        t_in_data;    // transformed version of in_data for easier input
    logic [NumOfNerves-1:0][M_W_BitSize-1:0]    in_w;
    logic [NumOfNerves-1:0][BitSize-1:0]        in_pa;
    logic [NumOfNerves-1:0][BitSize-1:0]        out_array;
    logic [NumOfNerves+NumOfInputs-1:0]         done_check;
    logic done_latch;
    logic [NumOfInputs-1:0] inc_buffer;

    // assign t_in_data = in_data;  // this bugs it out for some reason, making the first column in_a == second column in_a
    assign out_data = out_array;
    assign in_w = in_weights;
    assign in_pa = in_partial_sum;
    assign out_start = done_check[NumOfInputs] && in_valid;
    assign out_valid = (done_check[NumOfInputs+NumOfNerves-1:NumOfInputs] != 0) && in_valid;

    always_ff @(posedge clk) begin
        if (!res_n) begin
            // counter_w       <= 'b0;
            done_check      <= 'b0;
            done_latch      <= 'b0;
            inc_buffer <= '0;
            // out_valid       <=  0;
        end
        else begin
            // if ((counter_w < NumOfInputs + 1) /*&& in_w_en*/) begin
            //     counter_w   <= counter_w + 1;
            // end
            inc_buffer <= {inc_buffer, in_start};
            if (in_valid) done_check      <= {done_check, in_start && in_valid};
            // done_check[0]   <= in_start && in_valid;
            done_latch      <= (!in_start) ? ((out_valid) ? 1 : done_latch) : 0;
            // out_valid       <= (done_check[NumOfInputs+NumOfNerves-2:NumOfInputs-1] != 0) && in_valid;
        end
    end 

    // condition for when there is output: counter_in_r > NumOfInputs + NumOfNerves
    always_comb begin
        t_in_data = in_data;
        // en_l_b = (counter_w == NumOfInputs) ? 1'b1 : 1'b0;
        out_done  = (done_latch && in_valid && !out_valid) ? 1 : 0;
        // out_data = out_array;
    end

    genvar i;
    genvar j;
    generate;
        for (i = 0; i < NumOfInputs; i = i + 1) begin : si            // row      -> corresponds to the number of inputs
            for (j = 0; j < NumOfNerves; j = j + 1) begin :sj         // column   -> corresponds to the number of nerves in layer
                logic [BitSize-1:0]         out_a;
                logic [Weight_BitSize-1:0]     out_b;
                logic [BitSize-1:0]         out_ps;
                logic                       out_inc;
                if (i == 0 && j == 0) begin
                    systolic_pe #(.BitSize(BitSize), .Weight_BitSize(Weight_BitSize), .Depth(DepthIn), .Offset(0)) s_block 
                        (.clk(clk), .res_n(res_n), .in_valid(in_valid), .en_l_b(en_l_b), .in_a(t_in_data[NumOfInputs-1]), .in_b(in_w[NumOfNerves-1-j][Weight_BitSize-1:0]), //.in_w_en(in_w_en),
                        .in_partial_sum(in_pa[NumOfNerves-1-j]), .out_a(si[i].sj[j].out_a), .out_b(si[i].sj[j].out_b), .out_partial_sum(si[i].sj[j].out_ps),
                        .in_increment(inc_buffer[0]), .out_increment(out_inc));
                end
                else if (i == 0) begin
                    systolic_pe #(.BitSize(BitSize), .Weight_BitSize(Weight_BitSize), .Depth(DepthIn), .Offset(j)) s_block 
                        (.clk(clk), .res_n(res_n), .in_valid(in_valid), .en_l_b(en_l_b), .in_a(si[i].sj[j-1].out_a), .in_b(in_w[NumOfNerves-1-j][Weight_BitSize-1:0]), //.in_w_en(in_w_en),
                        .in_partial_sum(in_pa[NumOfNerves-1-j]), .out_a(si[i].sj[j].out_a), .out_b(si[i].sj[j].out_b), .out_partial_sum(si[i].sj[j].out_ps),
                        .in_increment(si[i].sj[j-1].out_inc), .out_increment(out_inc));
                end
                else if (j == 0) begin
                    systolic_pe #(.BitSize(BitSize), .Weight_BitSize(Weight_BitSize), .Depth(DepthIn), .Offset(i)) s_block 
                        (.clk(clk), .res_n(res_n), .in_valid(in_valid), .en_l_b(en_l_b), .in_a(t_in_data[NumOfInputs-1-i]), .in_b(si[i-1].sj[j].out_b), //.in_w_en(in_w_en),
                        .in_partial_sum(si[i-1].sj[j].out_ps), .out_a(si[i].sj[j].out_a), .out_b(si[i].sj[j].out_b), .out_partial_sum(si[i].sj[j].out_ps),
                        .in_increment(inc_buffer[i]), .out_increment(out_inc));
                end
                else begin
                    systolic_pe #(.BitSize(BitSize), .Weight_BitSize(Weight_BitSize), .Depth(DepthIn), .Offset(i+j)) s_block 
                    (.clk(clk), .res_n(res_n), .in_valid(in_valid), .en_l_b(en_l_b), .in_a(si[i].sj[j-1].out_a), .in_b(si[i-1].sj[j].out_b), //.in_w_en(in_w_en),
                    .in_partial_sum(si[i-1].sj[j].out_ps), .out_a(si[i].sj[j].out_a), .out_b(si[i].sj[j].out_b), .out_partial_sum(si[i].sj[j].out_ps),
                    .in_increment(si[i].sj[j-1].out_inc), .out_increment(out_inc));
                end
            end
        end
    endgenerate

    // generate
    //     if (NumOfNerves < NumOfInputs) begin
    //         assign out_valid = done_check[NumOfInputs-1] && in_valid;
    //     end
    //     else begin
    //         assign out_valid = (done_check[NumOfInputs+NumOfNerves-1:NumOfInputs-1] != 0) && in_valid;
    //     end
    // endgenerate

    // assigning output
    generate;
        for (genvar k = 0; k < NumOfNerves; k = k + 1) begin : sk 
            assign out_array[NumOfNerves-k-1] = si[NumOfInputs-1].sj[k].out_ps;
        end
    endgenerate


    
endmodule
