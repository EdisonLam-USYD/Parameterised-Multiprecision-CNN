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

module TB_conv_buffer;

    localparam BitSize = 4;
    localparam N = 3;
    localparam ImageWidth = 4;

    logic clk;
    logic res_n;
    logic in_valid;
    logic [BitSize-1:0] in_data;
//    logic in_done;
    logic out_ready;
    logic out_valid;
    logic [N-1:0][N-1:0][BitSize-1:0] out_data;
    logic out_done;
//    logic [BitSize-1:0] out_data_vis [N-1:0][N-1:0];
    
    logic [ImageWidth*ImageWidth-1:0][BitSize-1:0] test_image;
    logic [BitSize-1:0] a;
    logic [BitSize-1:0] b;
    logic [BitSize-1:0] c;
    logic [BitSize-1:0] d;

    
    convolution_buffer #(.N(N), .BitSize(BitSize), .ImageWidth(ImageWidth)) conv_b 
        (.clk(clk), .res_n(res_n), .in_valid(in_valid), .in_data(in_data), .out_valid(out_valid), .out_data(out_data), .out_ready(out_ready), .out_done(out_done));

//    assign {>>{out_data_vis}} = out_data;
    
    initial
    begin
        // $monitor("@ %0t:\n\t\t%b %b\n %b", $time);
        a = 4'b0111; // 7
        b = 4'b0010; // 2
        c = 4'b1111; //15
        d = 4'b1000; // 8
        test_image =   {a, b, b, c,
                        d, d, c, a,
                        c, b, d, d,
                        c, d, d, d};
        res_n = 0;
        clk = 0;
        #5
        clk = 1;
        in_valid = 0;
        #5
        res_n = 1;
        clk = 0;
        
        $monitor("@ %0t:\tbuffer_r = %p\n\t\t\tout = %p, out_valid = %b, pos_c = %d\n\t\t\trow_c = %d, out_ready = %b", 
            $time, conv_b.data_stream_c, out_data, out_valid, conv_b.image_pos_c, conv_b.image_row_c, conv_b.out_ready);
        clk = 0;
        for (int counter = 1; counter <= ImageWidth*ImageWidth; counter = counter + 1) begin
            #5
            in_data = test_image[ImageWidth*ImageWidth - counter];
//            in_done = (ImageWidth*ImageWidth - counter == 0) ? 1 : 0;
            in_valid = 1;
            clk = 1;
            #5
            clk = 0;          
        end
        for (int counter = 0; counter < ImageWidth*(N-1)/2 + (N-1)/2 + 1; counter = counter + 1) begin
            #5
            in_data = 0;
            in_valid = 0;
            clk = 1;
            #5
            clk = 0;
        end

    end


endmodule