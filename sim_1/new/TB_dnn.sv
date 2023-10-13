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

module TB_dnn;
    localparam BitSize          = 4;
    localparam ImageSize        = 4; 
    localparam NumOfImages      = 2;
    // localparam NumOfPEPerInput  = 1;
     localparam NumIn      = 2;
    // localparam CyclesPerPixel   = 2;
    localparam MaxNumNerves = 3;
    localparam M_W_BitSize      = 4;
    localparam integer LNN [1:0] = '{2, 3};

    logic clk;
    logic res_n;
    logic [NumOfImages-1:0] in_valid;
    logic [NumIn-1:0][BitSize-1:0] in_data;
    // logic [NumOfImages-1:0][ImageSize-1:0][BitSize-1:0] inputs;
    logic [ImageSize-1:0][BitSize-1:0] in_a;
    logic [ImageSize-1:0][BitSize-1:0] in_b;

    logic [MaxNumNerves-1:0][M_W_BitSize-1:0] in_weight;

    logic out_ready;
    logic out_valid;
    logic out_done;
    logic [2:0][BitSize-1:0] out_data;

    dnn_top #(
        .BitSize(BitSize), .M_W_BitSize(M_W_BitSize), .NumIn(2), .MaxNumNerves(3), .NumOfImages(NumOfImages),
        .CyclesPerPixel(1), .ImageSize(ImageSize), .NumLayers(2), .LWB('{4, 2}), .LNN('{2, 3}) 
    ) dnn_inst (
        .clk(clk), .res_n(res_n), .in_valid(in_valid), .in_data(in_data), .in_weights(in_weight), 
        .out_ready(out_ready), .out_data(out_data), .out_valid(out_valid), .out_done(out_done)
    );

    // testing array parameters: (works)
    // initial begin
    //     for (int i = 0; i < 5; i = i + 1) begin
    //         $display("i = %d: a[i] = %d", i, a[i]);
    //     end
    // end

    logic [M_W_BitSize-1:0] a;
    logic [M_W_BitSize-1:0] b;
    logic [M_W_BitSize-1:0] c;
    logic [M_W_BitSize-1:0] d;
    logic [ImageSize-1:0][LNN[1]-1:0][M_W_BitSize-1:0] weights0;
    logic [LNN[1]-1:0][LNN[0]-1:0][M_W_BitSize-1:0] weights1;

    logic [ImageSize-1:0][NumIn-1:0][BitSize-1:0] a_matrix;

    initial begin 
        // monitor to check the loading in of weights
       $monitor("@%0t: \n\tres_n = %b, in_weight = %p, weight_en = %p \n\tout_ready = %p", $time, res_n, in_weight, dnn_inst.weight_en, out_ready); 
        in_a = {BitSize'(4), BitSize'(4), BitSize'(4), BitSize'(4)};
        in_b = {BitSize'(3), BitSize'(3), BitSize'(3), BitSize'(3)};

        a = 4'b0001;
        b = 4'b0010;
        c = 4'b0011;
        d = 4'b0000;
        weights0 = {{c, d},
                    {a, c},
                    {d, c},
                    {a, b}};

        weights1 = {{c, d, c},
                    {a, b, c}};
        
        a_matrix = {{a, b}, {c, d}, {b, c}, {a, a}};

        // Setup:
        res_n = 0;
        in_valid = 0;
        clk = 0;

        // starting the weight loading process on next posedge clock
        for (int i = 0; i < ImageSize; i = i + 1) begin
            #10
            in_weight = {weights0[i], M_W_BitSize'(0)}; // in_weight = {weights0[ImageSize-1-i], M_W_BitSize'(0)};
            clk = 1;
            #10
            res_n = 1;
            clk = 0;
        end

        for (int i = 0; i < LNN[1]; i = i + 1) begin
            #10
            in_weight = {weights1[i]};                     // in_weight = {weights1[LNN[1]-1-i]};
            clk = 1;
            #10
            clk = 0;
        end
        // loading in weights  done

        // inputting a_matrix:
        for (int i = 0; i < ImageSize; i = i + 1) begin
            #10
            in_data = a_matrix[ImageSize-1-i];
            in_valid = '1; // since CyclesPerPixel is 1
            clk = 1;
            #10
            clk = 0;
        end
        for (int i = 0; i < NumOfImages-1; i = i + 1) begin // exact number of spare empty in_valids required
            #10
            in_data = '0;
            in_valid = '1; // since CyclesPerPixel is 1
            clk = 1;
            #10
            clk = 0;
        end
        
        for (int i = 0; i < 20; i = i + 1) begin // exact number of spare empty in_valids required
            #10
            in_data = '0;
            in_valid = '1; // since CyclesPerPixel is 1
            clk = 1;
            #10
            clk = 0;
        end

        #10
        in_weight = '0;
        in_valid = 0;
        clk = 1;
        #10
        clk = 0;
        #10
        in_weight = '0;
        in_valid = 0;
        clk = 1;
        #10
        clk = 0;

    end
endmodule