`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Edison Lam
// 
// Create Date: 18.10.2023
// Design Name: 
// Module Name: fc_top
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

// For testing, will manually have to edit stored weights and values
// details on array parameters: https://asic4u.wordpress.com/2016/01/23/passing-array-as-parameters/

// dnn_top #(
//     .BitSize(), .M_W_BitSize(), .NumIn(), .MaxNumNerves(), .NumOfImages(),
//     .CyclesPerPixel(), .ImageSize(), .NumLayers(2), .LWB(`{4, 2}), .LNN(`{3, 3})
// ) dnn_inst (
//     .clk(), .res_n(), .in_valid(), .in_data(), .in_weights(), 
//     .out_ready(), .out_data(), .out_valid(), .out_done()
// )
module fc_top 
#(
    BitSize = 8, M_W_BitSize = 4, NumLayers = 2, MaxNumNerves = 8, NumOfImages = 4,
    CyclesPerPixel = 4, ImageSize = 4, NumIn = 4, 
    integer LWB [NumLayers-1:0] = '{4, 2}, 
    integer LNN [NumLayers-1:0] = '{8, 4},
    integer DepthOut [NumLayers-1:0] = '{2, 1} // output layer will typically have a depth out of 1
)
(
    input                                       clk,
    input                                       res_n,
    input                                       in_fl_res,      // control signal to clear flattening layer buffers
    input [NumOfImages-1:0]                     in_valid,
    input [NumIn-1:0][BitSize-1:0]              in_data,
    input [MaxNumNerves-1:0][M_W_BitSize-1:0]   in_weights,
    input [NumLayers-1:0]                       in_load_weights,

    output [LNN[0]/DepthOut[0]-1:0][BitSize-1:0]    out_data,
    output                              out_valid,
    output                              out_done
);

    // Parameters for loading in weights
    // parameter integer [NumLayers-1:0] w_b = `{4, 2};

    // it takes N number of cycles to load in the weights of each nerve layer 
    // where N is the number of outputs of the previous layer

    // parameter integer LWB [NumLayers-1:0] = '{4, 2};        // LWB = Layer Weighted Bitsize
    // parameter integer LNN [NumLayers-1:0] = '{3, 3};        // LNN = Layer Number of Nerves (i.e number of inputs to the next layer)

    logic fl_out_valid;
    logic [ImageSize-1:0][BitSize-1:0] fl_out_data;
    logic fl_out_ready;
    logic fl_out_start;

    flattening_layer #(.BitSize(BitSize), .ImageSize(ImageSize), .NumOfImages(NumOfImages), .NumOfInputs(NumIn), .CyclesPerPixel(CyclesPerPixel))
        f_layer0 (.clk(clk), .res_n(res_n && !in_fl_res), .in_valid(in_valid), .in_data(in_data), .out_ready(fl_out_ready), .out_valid(fl_out_valid), 
        .out_data(fl_out_data), .out_start(fl_out_start));

    logic fl_out_ready_p;
    logic fl_out_valid_p;
    logic fl_out_start_p;
    logic [ImageSize-1:0][BitSize-1:0] fl_out_data_p;

    always_ff @(posedge clk) begin
        fl_out_ready_p  <= fl_out_ready;
        fl_out_valid_p  <= fl_out_valid;
        fl_out_start_p  <= fl_out_start;
        fl_out_data_p   <= fl_out_data;
    end

    genvar i;
    generate 
        for (i = 0; i < NumLayers; i = i + 1) begin : dense_layer
            logic nl_out_valid;
            logic nl_out_done;
            logic nl_out_start;

            logic nl_in_valid;
            logic nl_in_done;
            logic nl_in_start;

            logic [LNN[NumLayers-1-i]/DepthOut[NumLayers-1-i]-1:0][BitSize-1:0] nl_out;
            logic [LNN[NumLayers-1-i]/DepthOut[NumLayers-1-i]-1:0][BitSize-1:0] nl_in;

            if (i < NumLayers - 1) begin
                always_ff @(posedge clk) begin
                    nl_in_valid    <= nl_out_valid;
                    nl_in_done     <= nl_out_done;
                    nl_in_start    <= nl_out_start;
                    nl_in          <= (!nl_out_done) ? nl_out : '0;
                end
            end
            
            if (i == 0) begin
                // out_ready can be used to signal which array has not been loaded yet
                fc_layer #(.BitSize(BitSize), .Weight_BitSize(LWB[NumLayers-1-i]), .M_W_BitSize(M_W_BitSize), .NumOfInputs(ImageSize), 
                        .NumOfNerves(LNN[NumLayers-1-i]), .DepthIn(NumOfImages), .DepthOut(DepthOut[NumLayers-1-i])) 
                    fully_connected_layer (.clk(clk), .res_n(res_n), .in_valid(fl_out_valid_p), 
                    .in_start(fl_out_start_p), .in_data(fl_out_data_p), .en_l_b(in_load_weights[NumLayers-1-i]), 
                    .in_weights(in_weights[MaxNumNerves-1:MaxNumNerves-LNN[NumLayers-1-i]]), .in_partial_sum('0 /*in_partial_sum*/), 
                    .out_valid(nl_out_valid), .out_done(nl_out_done), .out_data(nl_out), .out_start(nl_out_start));

            end
            else begin
                fc_layer #(.BitSize(BitSize), .Weight_BitSize(LWB[NumLayers-1-i]), .M_W_BitSize(M_W_BitSize), .NumOfInputs(LNN[NumLayers-i]/DepthOut[NumLayers-i]), 
                        .NumOfNerves(LNN[NumLayers-1-i]), .DepthIn(DepthOut[NumLayers-i]), .DepthOut(DepthOut[NumLayers-1-i])) 
                    fully_connected_layer (.clk(clk), .res_n(res_n), .in_valid(dense_layer[i-1].nl_in_valid || dense_layer[i-1].nl_in_done), 
                    .in_start(dense_layer[i-1].nl_in_start), .in_data(dense_layer[i-1].nl_in), .en_l_b(in_load_weights[NumLayers-1-i]),
                    .in_weights(in_weights[MaxNumNerves-1:MaxNumNerves-LNN[NumLayers-1-i]]), .in_partial_sum('0 /*in_partial_sum*/), 
                    .out_valid(nl_out_valid), .out_done(nl_out_done), .out_data(nl_out), .out_start(nl_out_start));

            end

            logic temp_out_ready;

        end
        assign out_valid    = dense_layer[NumLayers-1].nl_out_valid;
        assign out_data     = dense_layer[NumLayers-1].nl_out;
        assign out_done     = dense_layer[NumLayers-1].nl_out_done;
    endgenerate
    
endmodule