`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.10.2023 15:36:35
// Design Name: 
// Module Name: TB_top
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


module TB_top;


    localparam BitSize = 4;
    localparam N = 2;
    localparam ImageWidth = 8;
    localparam Stride = 2;
    
    localparam C1CyclesPerPixel = 2;
    localparam C1NumberOfK      = 4;
    localparam C1KernelBitSize  = 2;
    
    localparam C2CyclesPerPixel = 4;
    localparam C2NumberOfK      = 8;
    localparam C2KernelBitSize  = 4;
    localparam C2ProcessingElements = 2;


    localparam [C1KernelBitSize*(N*N)-1:0] C1kernel [C1NumberOfK-1:0]
                        = {18'b000110110001101100,
                           18'b111111101010010101,
                           18'b111111101010010101,
                           18'b110100100011001011};

    localparam [C2KernelBitSize*(N*N)-1:0] C2kernel [C2NumberOfK-1:0]
                        = {36'b001011000010101010010011101110001111,
                           36'b110101000010011100011100000010110010,
                           36'b010000010011001110110110001010001100,
                           36'b100110111000111111101111100100100010,
                           36'b101111010111101011010011101101001001,
                           36'b001110110011000011110111110010010011,
                           36'b111101101101111101100100111110101100,
                           36'b110101111110110010011111001100101101};
    
    
    logic                                           clk;
    logic                                           res_n;
    logic                                           in_valid;
    logic [BitSize-1:0]                             in_data;
    
    
    // CHANGE THIS TO DNN OUTPUTS
    logic                                           out_ready;
    logic [C2NumberOfK-1:0]                         out_valid;
    logic [C2ProcessingElements-1:0][BitSize-1:0]   out_data;

    logic [ImageWidth*ImageWidth-1:0][BitSize-1:0]  test_image;
    logic [BitSize-1:0]                             a;
    logic [BitSize-1:0]                             b;
    logic [BitSize-1:0]                             c;
    logic [BitSize-1:0]                             d;



    top #(.N(), .BitSize(BitSize), .ImageWidth(ImageWidth), .PoolingN(), 
    .C1NumberOfK(C1NumberOfK), .C2NumberofK(C2NumberOfK), .C2ProcessingElements(C2ProcessingElements),
    .C1KernelBitSize(C1KernelBitSize), .C2KernelBitSize(C2KernelBitSize),
    .C1kernel(C1kernel), .C2kernel(C2kernel),
    // dnn top parameters
    .M_W_BitSize (), .NumLayers(), .MaxNumNerves(),
    .LWB(), .LNN()
    ) top (
        .clk(clk),
        .res_n(res_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .in_weights(),
        .out_ready(),
        .out_data(),
        .out_valid(),
        .out_done()
    );


    initial
    begin
        // $monitor("@ %0t:\n\t\t%b %b\n %b", $time);
        a = 4'b0111;
        b = 4'b0010;
        c = 4'b1111;
        d = 4'b1000;
        test_image =   {a, b, b, c, b, c, a, c,
                        d, d, c, a, c, a, b, c,
                        c, b, d, d, d, d, d, a,
                        b, a, b, c, d, a, d, c,
                        c, d, d, d, d, d, a, d,
                        d, d, c, a, c, a, c, a,
                        c, b, d, d, d, d, b, c,
                        b, b, c, c, a, d, c, b};
        res_n = 0;
        clk = 1;
        #2
        res_n = 1;
        clk = 0;
      


        for (int counter = 1; counter <= ImageWidth*ImageWidth*8; counter = counter) begin
            #10
            clk = 1;
            if(counter <= ImageWidth*ImageWidth) begin
                in_data = test_image[ImageWidth*ImageWidth - counter];
                in_valid = 1;
            end
            else begin
                in_data = '0;
                in_valid = '0;
            end
            #10
            clk = 0;
            if (out_ready) begin
                counter = counter + 1;
            end
          
        end
    end

endmodule
