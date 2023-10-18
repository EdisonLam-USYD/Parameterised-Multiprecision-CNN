`timescale 1ns / 1ps

module top_v2 #(
    // convolution + pooling layer(s) top parameters
    N = 3, BitSize = 32, ImageWidth = 8, PoolingN = 2, 
    C1NumberOfK = 4, C2NumberOfK = 4, C2ProcessingElements = 2,
    C1KernelBitSize = 4, C2KernelBitSize = 4,
    [C1KernelBitSize*(N*N)-1:0] C1kernel [C1NumberOfK-1:0] = {'0,'0,'0,'0},
    [C2KernelBitSize*(N*N)-1:0] C2kernel [C2NumberOfK-1:0] = {'0,'0,'0,'0},
    // dnn top parameters
    M_W_BitSize = 8, NumLayers = 4, MaxNumNerves = 8,
    integer LWB [NumLayers-1:0] = '{4, 2, 8, 2}, // left to right 
    integer LNN [NumLayers-1:0] = '{2, 8, 4, 6}, // left to right
    integer DNN_Depths [NumLayers-1:0] = '{1, 4, 2, 1},   // left to right
    LatencyDelay = 3                        // increase to ensure all output of the FCL is given in one go (required due to no stall signals)
    )
    (
        input 						                        clk,
        input                                               res_n,
        input 						                        in_valid,
        input [BitSize-1:0] 	                            in_data,
        input [MaxNumNerves-1:0][M_W_BitSize-1:0]           in_weights,
        input [NumLayers-1:0]                               in_load_weights,

        output                                              out_ready,
        output [LNN[0]/DNN_Depths[0]-1:0][BitSize-1:0]      out_data,
        output                                              out_valid,
        output                                              out_done
    );

    localparam C1CyclesPerPixel = C1NumberOfK/2;
    localparam C2CyclesPerPixel = C2NumberOfK/C2ProcessingElements;


    logic [C2NumberOfK-1:0]                           C2_out_valid;
    logic [C2ProcessingElements-1:0][BitSize-1:0]       C2_out_data;
    logic C2_out_set_done;
    logic out_ready_conv;

    assign out_ready = out_ready_conv;

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
        .out_ready(out_ready_conv),
        .out_valid(C2_out_valid),
        .out_data(C2_out_data),
        .out_set_done(C2_out_set_done)
    );

    logic [C2NumberOfK-1:0]                     dnn_in_valid;
    logic [C2ProcessingElements-1:0][BitSize-1:0] dnn_in_data;
    logic                                       dnn_in_set_done;
    logic in_fl_res;

    fc_top #(
        .BitSize(BitSize), .M_W_BitSize(M_W_BitSize), .NumIn(C2ProcessingElements), .MaxNumNerves(MaxNumNerves), .NumOfImages(C2NumberOfK), // only does C2NumberOfK before requiring a reset
        .CyclesPerPixel(C2CyclesPerPixel), .ImageSize((ImageWidth/(PoolingN**2))**2), .NumLayers(NumLayers), .LWB(LWB), .LNN(LNN), .DepthOut(DNN_Depths)
    ) dnn_inst (
        .clk(clk), .res_n(res_n), .in_fl_res(in_fl_res), .in_valid(dnn_in_valid), .in_data(dnn_in_data), .in_weights(in_weights), 
        .in_load_weights(in_load_weights), .out_data(out_data), .out_valid(out_valid), .out_done(out_done)
    );

    logic [$clog2(C2NumberOfK + MaxNumNerves + LatencyDelay)+1:0] in_fl_counter_r;
    logic [$clog2(C2NumberOfK + MaxNumNerves + LatencyDelay)+1:0] in_fl_counter_c;


    always_ff @(posedge clk) begin
        if (!res_n) begin
            in_fl_counter_r <= '0;
            dnn_in_valid    <= '0;
            dnn_in_data     <= '0;
            dnn_in_set_done <= 0;
            in_fl_res       <= 0;
        end
        else begin
            in_fl_counter_r <= in_fl_counter_c;
            dnn_in_valid    <= {<<{C2_out_valid}};
            dnn_in_data     <= C2_out_data;
            dnn_in_set_done <= C2_out_set_done;
            in_fl_res       <= (in_fl_counter_r == C2NumberOfK + MaxNumNerves + LatencyDelay) ? 1 : 0;
        end
    end

    always_comb begin
        in_fl_counter_c = in_fl_counter_r;
        case (in_fl_counter_c)
            C2NumberOfK + MaxNumNerves + LatencyDelay + 1: begin
                in_fl_counter_c = 0;
            end
            '0          : begin
                in_fl_counter_c = (dnn_in_set_done) ? in_fl_counter_c + 1 : 0;
            end
            default     : begin
                in_fl_counter_c = in_fl_counter_c + 1;
            end
        endcase
            
    end

endmodule