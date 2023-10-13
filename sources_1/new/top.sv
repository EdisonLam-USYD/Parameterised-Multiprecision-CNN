`timescale 1ns / 1ps

module top #(
    // convolution + pooling layer(s) top parameters
    N = 3, BitSize = 32, ImageWidth = 8, PoolingN = 2, 
    C1NumberOfK = 4, C2NumberOfK = 4, C2ProcessingElements = 2,
    C1KernelBitSize = 4, C2KernelBitSize = 4,
    [C1KernelBitSize*(N*N)-1:0] C1kernel [C1NumberOfK-1:0] = {'0,'0,'0,'0},
    [C2KernelBitSize*(N*N)-1:0] C2kernel [C2NumberOfK-1:0] = {'0,'0,'0,'0},
    // dnn top parameters
    M_W_BitSize = 16, NumLayers = 4, MaxNumNerves = 6,
    CyclesPerPixel = 4, ImageSize = 16, integer LWB [NumLayers-1:0] = '{4, 2, 4, 8}, // left to right 
    integer LNN [NumLayers-1:0] = '{2, 3, 5, 6} // left to right
    )
    (
        input 						                        clk,
        input                                               res_n,
        input 						                        in_valid,
        input [BitSize-1:0] 	                            in_data,
        input [MaxNumNerves-1:0][M_W_BitSize-1:0]           in_weights,

        output                                              out_ready,
        output [LNN[0]-1:0][BitSize-1:0]                    out_data,
        output                                              out_valid,
        output                                              out_done
    );

    logic [C2NumberOfK-1:0]                           C2_out_valid;
    logic [C2ProcessingElements:0][BitSize-1:0]       C2_out_data;
    logic C2_out_set_done;

    conv_pooling_top #(.N(N), .BitSize(BitSize), .ImageWidth(ImageWidth), .Stride(PoolingN),
        .C1CyclesPerPixel(C1CyclesPerPixel), .C2CyclesPerPixel(C2CyclesPerPixel),
        .C1NumberOfK(C1NumberOfK), .C2NumberOfK(C2NumberOfK), .C2ProcessingElements(C2ProcessingElements),
        .C1KernelBitSize(C1KernelBitSize), .C2KernelBitSize(C2KernelBitSize), 
        .C1kernel(C1kernel), .C2kernel(C2kernel)
    ) conv_p (
        .clk(clk),
        .res_n(res_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_ready(out_ready),
        .out_valid(C2_out_valid),
        .out_data(C2_out_data),
        .out_set_done(C2_out_set_done)
    );

    dnn_top #(
        .BitSize(BitSize), .M_W_BitSize(M_W_BitSize), .NumIn((ImageWidth/(PoolingN**2))**2), .MaxNumNerves(MaxNumNerves), .NumOfImages(C2NumberOfK), // only does C2NumberOfK before requiring a reset
        .CyclesPerPixel(C2NumberOfK/C2ProcessingElements), .ImageSize(ImageSize), .NumLayers(NumLayers), .LWB(LWB), .LNN(LNN) 
    ) dnn_inst (
        .clk(clk), .res_n(res_n), .in_fl_res(C2_out_set_done), .in_valid(C2_out_valid), .in_data(C2_out_data), .in_weights(in_weight), //. in_w_en(1),
        .out_ready(out_ready), .out_data(out_data), .out_valid(out_valid), .out_done(out_done)
    );




endmodule
