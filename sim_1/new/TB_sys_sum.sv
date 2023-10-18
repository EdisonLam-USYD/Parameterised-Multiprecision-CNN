`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.03.2023 18:33:34
// Design Name: 
// Module Name: TB_dotProduct
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

module TB_sys_sum;
    localparam BitSize          = 4;
    localparam ImageSize        = 3; 
    localparam NumOfNerves     = 2;

    logic clk;
    logic res_n;
    logic in_valid;
    logic in_start;
    logic [NumOfNerves-1:0][BitSize-1:0] in_data;

    // logic out_start;
    logic out_valid;
    logic out_start;
    logic [BitSize-1:0] out_data;

    sys_sum #(.BitSize(BitSize), .NumOfNerves(NumOfNerves), .DepthIn(2)) systolic_sum 
    (
        .clk(clk), .res_n(res_n), .in_valid(in_valid), .in_start(in_start), .in_data(in_data),  
        .out_start(out_start), .out_valid(out_valid), .out_data(out_data)
    );


    logic [BitSize-1:0] a;
    logic [BitSize-1:0] b;
    logic [BitSize-1:0] c;
    logic [BitSize-1:0] d;

    logic [ImageSize+NumOfNerves-2:0][NumOfNerves-1:0][BitSize-1:0] a_matrix;

    initial begin 
        // monitor to check the loading in of weights

        a = 4'b0001;
        b = 4'b0010;
        c = 4'b0011;
        d = 4'b0000;
        a_matrix = {{d, d},
                    {a, c},
                    {d, c},
                    {a, d}};

        // Setup:
        res_n = 0;
        in_start = 0;
        in_valid = 0;
        clk = 0;
        #5
        clk = 1;
        #5
        res_n = 1;
        clk = 0;

        // starting the weight loading process on next posedge clock
        for (int i = 0; i < 10; i = i + 1) begin
            #10
            clk = 1;
            // in_start = (i < ImageSize) ? 1 : 0;
            in_start = (i >= ImageSize) ? 0 : (i % 2 == 0) ? 1 : 0;
            in_valid = (i < ImageSize + NumOfNerves - 1) ? 1 : 0;
            // in_valid = (i < ImageSize) ? 1 : 0;
            in_data = (i < ImageSize + NumOfNerves - 1) ? a_matrix[i] : '0;
            #10
            clk = 0;
        end
        in_valid = 0;

        

    end
endmodule