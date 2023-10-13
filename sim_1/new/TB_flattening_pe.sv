`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.03.2023 18:33:34
// Design Name: 
// Module Name: TB_flattening_pe
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

module TB_flattening_pe;

    localparam BitSize = 4;
    localparam N = 3;
    localparam ImageWidth = 3;

    logic clk;
    logic res_n;
    logic in_valid;
    logic [BitSize-1:0] in_data;

    logic [N-1:0][N-1:0][BitSize-1:0] out_data;
    logic out_done;

    logic [ImageWidth*ImageWidth-1:0][BitSize-1:0] test_image;


    
    flattening_pe #(.BitSize(BitSize), .ImageSize(ImageWidth*ImageWidth), .Delay(3)) flat_pe 
        (.clk(clk), .res_n(res_n), .in_valid(in_valid), .in_data(in_data), .out_data(out_data), .out_done(out_done));

//    assign {>>{out_data_vis}} = out_data;
    
    initial
    begin

        test_image = {
            BitSize'(1),
            BitSize'(2),
            BitSize'(3),
            BitSize'(4),
            BitSize'(5),
            BitSize'(6),
            BitSize'(7),
            BitSize'(8),
            BitSize'(9)
        };
        
        res_n = 0;
        in_data = '0;
        clk = 0;
        #5
        clk = 1;
        in_valid = 0;
        #5
        res_n = 1;
        clk = 0;
        
        // $monitor("@ %0t:\tbuffer_r = %p\n\t\t\tout = %p, out_valid = %b, pos_c = %d\n\t\t\trow_c = %d, out_ready = %b", 
        //     $time, conv_b.data_stream_c, out_data, out_valid, conv_b.image_pos_c, conv_b.image_row_c, conv_b.out_ready);

        for (int counter = 0; counter < ImageWidth*ImageWidth; counter = counter + 1) begin
            #5
            in_data = test_image[ImageWidth*ImageWidth - 1 - counter];
//            in_done = (ImageWidth*ImageWidth - counter == 0) ? 1 : 0;
            in_valid = 1;
            clk = 1;
            #5
            clk = 0;          
        end
        for (int counter = 0; counter < ImageWidth*(N-1)/2 + (N-1)/2 + 1; counter = counter + 1) begin
            #5
            in_data = 0;
            in_valid = 1;
            clk = 1;
            #5
            clk = 0;
        end

    end


endmodule