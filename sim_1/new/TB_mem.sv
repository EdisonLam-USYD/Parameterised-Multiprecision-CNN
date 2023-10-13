`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2023 21:05:38
// Design Name: 
// Module Name: TB_nerveLayers
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


module TB_mem;

    localparam nok = 4;
    localparam bs = 32;
    localparam npe = 2;
    localparam iw = 2;

    logic                   clk;
    logic                   res_n;
    logic [nok-1:0]         in_valid;
    logic [npe-1:0][bs-1:0] in_data;
    logic [bs-1:0]          out_data;
    logic                   out_valid;
    logic                   image_done;

    mem_module #(.NumberOfK(nok), .BitSize(bs), .ProcessingElements(npe), .ImageWidth(iw))
        mem (.clk(clk), .res_n(res_n), .in_valid(in_valid), .in_data(in_data),
        .out_data(out_data), .out_valid(out_valid), .image_done(image_done));


    logic [nok-1:0][iw*iw-1:0][bs-1:0] images;
    logic [iw*iw-1:0][bs-1:0] a;
    logic [iw*iw-1:0][bs-1:0] b;
    logic [iw*iw-1:0][bs-1:0] c;
    logic [iw*iw-1:0][bs-1:0] d;

    initial begin
        // set-up
        a = {(iw*iw){bs'(4)}}; // inputted left to right
        b = {(iw*iw){bs'(3)}};
        c = {(iw*iw){bs'(2)}};
        d = {(iw*iw){bs'(1)}};
        images = {a, b, c, d};
        
        clk = 0;
        res_n = 0;
        in_valid = '0;
        #5
        clk = 1;
        #5
        res_n = 1;
        clk = 0;

        // loading in the values
        for (int i = 0 ; i < iw*iw; i = i + 1) begin
            for (int j = 0; j < (nok/npe); j = j + 1) begin
                #10
                if (j == 0) in_valid = {1'b0, 1'b0, 1'b1, 1'b1};
                else if (j == 1) in_valid = {1'b1, 1'b1, 1'b0, 1'b0};
                else in_valid = '0;
                in_data = {images[j%nok][iw*iw-i-1], images[(npe*j + 1)%nok][iw*iw-i-1]};
                clk = 1;
                #10
                clk = 0;
            end
        end
        for (int i = 0; i < iw*iw*nok+1; i = i + 1) begin
            #10
            clk = 1;
            #10
            clk = 0;
        end


    end


endmodule