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

module TB_conv_pooling_layer;

    localparam BitSize = 4;
    localparam N = 2;
    localparam Stride = 2;
    localparam ImageWidth = 4;
    localparam K = 2;
    localparam NoK = 4;
    localparam CyclesPerPixel = 2;
    localparam ProcessingElements = (NoK+CyclesPerPixel-1)/CyclesPerPixel;


    localparam [K*(N*N)-1:0] kernels [NoK-1:0] =
            {18'b000110110001101100,
             18'b111111101010010101,
             18'b110100100011001011,
             18'b101010010101011000};

    // localparam [NoK-1:0][N-1:0][N-1:0][K-1:0] kernels =
    //     {{2'b00, 2'b01, 2'b10}, {2'b11, 2'b00, 2'b01}, {2'b10, 2'b11, 2'b00},
    //      {2'b11, 2'b11, 2'b11}, {2'b10, 2'b10, 2'b10}, {2'b01, 2'b01, 2'b01},
    //      {2'b11, 2'b01, 2'b00}, {2'b10, 2'b00, 2'b11}, {2'b00, 2'b10, 2'b11},
    //      {2'b10, 2'b10, 2'b10}, {2'b01, 2'b01, 2'b01}, {2'b01, 2'b10, 2'b00}};


    logic                                           clk;
    logic                                           res_n;
    logic                                           in_valid;
    logic [BitSize-1:0]                             in_data;
    logic                                           out_ready;
    logic [NoK-1:0]                                 out_valid;
    logic [ProcessingElements-1:0][BitSize-1:0]     out_data;
    logic [ImageWidth*ImageWidth-1:0][BitSize-1:0]  test_image;
    logic [BitSize-1:0]                             a;
    logic [BitSize-1:0]                             b;
    logic [BitSize-1:0]                             c;
    logic [BitSize-1:0]                             d;

    // logic [NoK-1:0][N-1:0][N-1:0][K-1:0] kernels;


    conv_pooling_layer #(.N(N), .BitSize(BitSize), .ImageWidth(ImageWidth),
    .NumberOfK(NoK), .KernelBitSize(K), .CyclesPerPixel(CyclesPerPixel), .Stride(Stride), .kernel(kernels)) conv_pooling
		(
    		.clk(clk),
            .res_n(res_n),
        	.in_valid(in_valid),
            // .kernel(kernels),   
            .in_data(in_data),
            .out_ready(out_ready),
        	.out_valid(out_valid),
            .out_data(out_data)
    );

    
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
        // kernels[0] = {{2'b00, 2'b01, 2'b10}, {2'b11, 2'b00, 2'b01}, {2'b10, 2'b11, 2'b00}};
        // kernels[1] = {{2'b11, 2'b11, 2'b11}, {2'b10, 2'b10, 2'b10}, {2'b01, 2'b01, 2'b01}};
        // kernels[2] = {{2'b11, 2'b01, 2'b00}, {2'b10, 2'b00, 2'b11}, {2'b00, 2'b10, 2'b11}};
        // kernels[3] = {{2'b10, 2'b10, 2'b10}, {2'b01, 2'b01, 2'b01}, {2'b01, 2'b10, 2'b00}};


        for (int counter = 1; counter <= ImageWidth*ImageWidth*3; counter = counter) begin
            #10
            if(counter <= ImageWidth*ImageWidth) begin
                in_data = test_image[ImageWidth*ImageWidth - counter];
                in_valid = 1;
            end
            else begin
                in_data = '0;
                in_valid = '0;
            end
            clk = 1;
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