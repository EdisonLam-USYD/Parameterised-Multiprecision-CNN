`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Edison Lam
// 
// Create Date: 25.04.2023 21:05:38
// Design Name: 
// Module Name: TB_nerveLayers
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Test bench for the 2D systolic array multiplier (depreciated)
// 
//////////////////////////////////////////////////////////////////////////////////

// Depreciated version, for implementation with PE reuse, use TB_fcl
module TB_nerveLayers;

    localparam BitSize = 8;
    localparam M_W_BitSize = 8;
    localparam Weight_BitSize = 2;
    localparam NumOfInputs = 2;
    localparam NumOfNerves = 3;
    localparam Height = 2;

    logic                                   clk;
    logic                                   res_n;
    logic                                   in_valid;
    logic                                   in_start;
    logic [NumOfInputs*BitSize-1:0]         in_data;
    logic [NumOfNerves*BitSize-1:0]         in_weights;
    logic [NumOfNerves*BitSize-1:0]         in_partial_sum;
    logic                                   en_l_b;

    logic                            out_valid;
    logic                            out_done;
    logic [NumOfNerves-1:0][BitSize-1:0]              out_data;

    systolic_array #(.BitSize(BitSize), .Weight_BitSize(Weight_BitSize), .M_W_BitSize(M_W_BitSize), .NumOfInputs(NumOfInputs), .NumOfNerves(NumOfNerves), .DepthIn(2)) 
        layer1 (.clk(clk), .res_n(res_n), .in_valid(in_valid), .in_start(in_start), .in_data(in_data), .in_weights(in_weights), .in_partial_sum(in_partial_sum), 
        .en_l_b(en_l_b), .out_valid(out_valid), .out_done(out_done), .out_data(out_data));

    logic [NumOfInputs-1:0][NumOfNerves-1:0][M_W_BitSize-1:0] weights;
    logic [3:0][NumOfInputs-1:0][BitSize-1:0] a_matrix;
    logic [M_W_BitSize-1:0] a;
    logic [M_W_BitSize-1:0] b;
    logic [M_W_BitSize-1:0] c;
    logic [M_W_BitSize-1:0] d;

    logic [BitSize-1:0] aaaaaaa;
    logic [BitSize-1:0] bbbbbbb;
    logic [BitSize-1:0] ccccccc;
    logic [BitSize-1:0] ddddddd;

    initial begin

        a = 4'b0011;
        b = 4'b0010;
        c = 4'b0001;
        d = 4'b0000;
        // weights =  {{a, d, a},
        //             {b, c, b},
        //             {c, c, c}};
        weights =  {{c, d, c},
                    {c, c, c}};
        aaaaaaa = 8'b00000111;
        bbbbbbb = 8'b00000110;
        ccccccc = 8'b00000101;
        ddddddd = 8'b00000000;
        // a_matrix = {{{aaaaaaa}, {ddddddd}, {ddddddd}},
        //             {{aaaaaaa}, {bbbbbbb}, {ddddddd}},
        //             {{ddddddd}, {bbbbbbb}, {aaaaaaa}},
        //             {{ddddddd}, {ddddddd}, {ccccccc}}};
        a_matrix = {{{aaaaaaa}, {ddddddd}},
                    {{ddddddd}, {bbbbbbb}},
                    {{aaaaaaa}, {ddddddd}},
                    {{ddddddd}, {bbbbbbb}}};
        res_n = 0;
        en_l_b = 0;
        clk = 0;
        in_weights = weights[0];
        in_partial_sum = 'b0;
        in_data = 'b0;
        in_start = 'b0;
        in_valid = 0;
        #5
        clk = 1;
        #5
        res_n = 1;
        clk = 0;
        // loading in weights
        for(int i = 1; i < NumOfInputs; i = i + 1) begin
            #10
            clk = 1;
            en_l_b = 1;
            in_weights = weights[i];
            #10
            clk = 0;
        end
        for(int i = 1; i < 2; i = i + 1) begin
            #10
            clk = 1;
            en_l_b = 1;
            #10
            clk = 0;
        end
        en_l_b = 0;
        // TODO: input data
        for(int i = 0; i < NumOfInputs+(Height-1); i = i + 1) begin
            #10
            clk = 1;
            in_valid = 1;
            in_data = a_matrix[3-i];
            in_start = (i % 2 == 0) ? 1 : 0;
            #10
            clk = 0;
        end
        for(int i = 0; i < NumOfNerves*2; i = i + 1) begin
            #10
            clk = 1;
            in_start = 0;
            in_data = 'b0;
            #10
            clk = 0;
        end

    end

endmodule
