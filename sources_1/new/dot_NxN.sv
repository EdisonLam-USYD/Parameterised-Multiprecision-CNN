`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Edison Lam
// 
// Create Date: 26.03.2023 16:32:27
// Design Name: 
// Module Name: dot_NxN
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

// testing for kernel precision of 1 bit
// dot_NxN #(.N(3), .BitSize(8), .KernelBitSize(1)) test1 (.kernel(), .in_data(), .out_data(), .sum());
module dot_NxN #(N = 3, BitSize=8, KernelBitSize = 4)
    (
    input [KernelBitSize*(N*N)-1:0] kernel,
    input signed [BitSize*(N*N)-1:0] in_data,
    output logic [BitSize*(N*N)-1:0] out_data,
    output logic [BitSize-1:0] sum
    );
    
//    logic [N*N-1:0] in_shell;   // ? x ? matrix from in_data (i.e. image)
//    logic [N*N-1:0][BitSize-1:0] pooling;    // 
    logic [N*N-1:0][KernelBitSize-1:0] kernel_layers;
    logic [N*N-1:0][BitSize-1:0] i_data_layers;
    logic [N*N-1:0][BitSize-1:0] o_data_layers;
    
    assign kernel_layers = kernel;
    assign i_data_layers = in_data;
    assign out_data = o_data_layers;
    
    genvar i;
    generate 
        if (KernelBitSize == 1) begin
            for (i = 0; i < N*N; i= i + 1) begin : _1BitDotProduct
                mul1bit mul1 (
                  .A(kernel_layers[i]),  // input wire [0 : 0] A
                  .B(i_data_layers[i]),  // input wire [7 : 0] B
                  .P(o_data_layers[i])  // output wire [8 : 0] P
                );
                // multiply_1Bit #(.BitSize(BitSize)) multi (
                //                             .in_data(i_data_layers[i]),
                //                             .i_prod(kernel_layers[i]),
                //                             .out_data(o_data_layers[i])
                //                             );
            end 
        end
        else if (KernelBitSize == 2) begin
            // not implemented yet
            for (i = 0; i < N*N; i= i + 1) begin : _2BitDotProduct
                mul2bit mul2 (
                  .A(kernel_layers[i]),  // input wire [1 : 0] A
                  .B(i_data_layers[i]),  // input wire [7 : 0] B
                  .P(o_data_layers[i])  // output wire [9 : 0] P
                );
                // multiply_2Bit #(.BitSize(BitSize)) multi (
                //                             .in_data(i_data_layers[i]),
                //                             .i_prod(kernel_layers[i]),
                //                             .out_data(o_data_layers[i])
                //                             );
            end 
        end
        else if (KernelBitSize == 4) begin
            for (i = 0; i < N*N; i= i + 1) begin : _4BitDotProduct
                mul4bit mul4 (
                  .A(kernel_layers[i]),  // input wire [3 : 0] A
                  .B(i_data_layers[i]),  // input wire [7 : 0] B
                  .P(o_data_layers[i])  // output wire [11 : 0] P
                );
                // multiply_4Bit #(.BitSize(BitSize), .FixedPointPos()) multi (
                //                             .in_data(i_data_layers[i]),
                //                             .i_prod(kernel_layers[i]),
                //                             .out_data(o_data_layers[i])
                //                             );
            end 
        end
        else if (KernelBitSize == 8) begin
            for (i = 0; i < N*N; i= i + 1) begin : _8BitDotProduct
                mul8bit mul8 (
                  .A(kernel_layers[i]),  // input wire [7 : 0] A
                  .B(i_data_layers[i]),  // input wire [7 : 0] B
                  .P(o_data_layers[i])  // output wire [15 : 0] P
                );
                // multiply_8Bit #(.BitSize(BitSize), .FixedPointPos()) multi (
                //                             .in_data(i_data_layers[i]),
                //                             .i_prod(kernel_layers[i]),
                //                             .out_data(o_data_layers[i])
                //                             );
            end 
        end
        else if (KernelBitSize == 16) begin
            for (i = 0; i < N*N; i= i + 1) begin : _16BitDotProduct
                mul16bit mul16 (
                  .A(kernel_layers[i]),  // input wire [7 : 0] A
                  .B(i_data_layers[i]),  // input wire [7 : 0] B
                  .P(o_data_layers[i])  // output wire [15 : 0] P
                );
            end 
        end
        else if (KernelBitSize == 32) begin
            for (i = 0; i < N*N; i= i + 1) begin : _32BitDotProduct
                mul32bit mul32 (
                  .A(kernel_layers[i]),  // input wire [7 : 0] A
                  .B(i_data_layers[i]),  // input wire [7 : 0] B
                  .P(o_data_layers[i])  // output wire [15 : 0] P
                );
            end 
        end
        
    endgenerate 
    /* verilator lint_off WIDTH */
    always_comb begin
        sum = 'b0;
        for (int i = 0; i < BitSize*(N*N); i = i + 1) begin
            sum = sum + out_data[i];
        end
    end

endmodule
