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

module TB_conv;

    // logic [`K*(`N*`N)-1:0] in_kernel;
    // logic [`B*(`N*`N)-1:0] in_conv;
   
    // logic [1:0] out;

    // logic [`IW-1:0][`IW-1:0][`B-1:0] image;
    // integer counter;
    // logic clk;
    // logic res_n;
    // logic in_valid;
    // logic out_ready;
    // logic [2:0][`IW-1:0][`B-1:0] out_data;

    localparam BitSize = 4;
    localparam N = 3;
    localparam ImageWidth = 4;
    localparam K = 2;
    localparam NoK = 4;
    localparam CyclesPerPixel = 2;
    localparam ProcessingElements = (NoK+CyclesPerPixel-1)/CyclesPerPixel;

    logic clk;
    logic res_n;
    logic in_valid;
    logic [BitSize-1:0] in_data;
    logic out_ready;
    logic out_valid;
    logic buffer_out_valid;
    logic [N-1:0][N-1:0][BitSize-1:0] buffer_out;
    logic [ProcessingElements-1:0][BitSize-1:0] out_data;

    logic [ImageWidth*ImageWidth-1:0][BitSize-1:0] test_image;
    logic [BitSize-1:0] a;
    logic [BitSize-1:0] b;
    logic [BitSize-1:0] c;
    logic [BitSize-1:0] d;

    logic [NoK-1:0][N-1:0][N-1:0][K-1:0] kernels;


    convolution_buffer #(.N(N), .BitSize(BitSize), .ImageWidth(ImageWidth)) conv_b 
        (.clk(clk), .res_n(res_n), .in_valid(in_valid), .in_data(in_data), .out_valid(buffer_out_valid), .out_data(buffer_out), .out_ready(out_ready), .out_done(out_done));


    convolution_stage #(.NumberOfK(NoK), .N(N), .BitSize(BitSize), .KernelBitSize(K), .ImageWidth(ImageWidth), .CyclesPerPixel(CyclesPerPixel)) conv_s 
        (.clk(clk), .res_n(res_n), .in_valid(buffer_out_valid), .kernel(kernels), .in_data(buffer_out), .out_ready(), .out_valid(out_valid), .out_data(out_data));

    initial
    begin
        // $monitor("@ %0t:\n\t\t%b %b\n %b", $time);
        a = 4'b0111;
        b = 4'b0010;
        c = 4'b1111;
        d = 4'b1000;
        test_image =   {a, b, b, c,
                        d, d, c, a,
                        c, b, d, d,
                        c, d, d, d};
        res_n = 0;
        clk = 1;
        #2
        res_n = 1;
        clk = 0;
        kernels[0] = {{2'b00, 2'b01, 2'b10}, {2'b11, 2'b00, 2'b01}, {2'b10, 2'b11, 2'b00}};
        kernels[1] = {{2'b11, 2'b11, 2'b11}, {2'b10, 2'b10, 2'b10}, {2'b01, 2'b01, 2'b01}};
        kernels[2] = {{2'b11, 2'b01, 2'b00}, {2'b10, 2'b00, 2'b11}, {2'b00, 2'b10, 2'b11}};
        kernels[3] = {{2'b10, 2'b10, 2'b10}, {2'b01, 2'b01, 2'b01}, {2'b01, 2'b10, 2'b00}};



        for (int counter = 1; counter <= ImageWidth*ImageWidth*2; counter = counter) begin
            #10
            clk = 1;
            in_data = test_image[ImageWidth*ImageWidth - counter];
            in_valid = 1;
            #10
            clk = 0;
            if (out_ready) begin
                counter = counter + 1;
            end
          
        end
    end

    // logic [`B-1:0] in_data = image[counter/`IW][counter%`IW];

    // always begin
    //     #10
    //     res_n = 1;
    //     if (out_ready) 
    //     begin
    //         counter = counter + 1;
    //     end
    //     in_valid = 1;
    //     clk = 1;
    //     #10
    //     clk = 0;
        
    // end

endmodule