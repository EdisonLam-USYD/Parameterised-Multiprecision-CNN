`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2023
// Design Name: 
// Module Name: convolution_buffer
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
module dnn_top_diagram 
#(
    BitSize = 8, M_W_BitSize = 4, NumIn = 4, NumLayers = 2, MaxNumNerves = 5, NumOfImages = 4,
    CyclesPerPixel = 4, ImageSize = 4, integer LWB [NumLayers-1:0] = '{4, 2}, integer LNN [NumLayers-1:0] = '{2, 5})
(
    input                                       clk,
    input                                       res_n,
    input                                       in_fl_res,
    input [NumOfImages-1:0]                     in_valid,
    input [NumIn-1:0][BitSize-1:0]              in_data,
    // input                                       in_w_en,
    input [MaxNumNerves-1:0][M_W_BitSize-1:0]   in_weights,
    input [NumLayers-2:0]               weight_en_posedge,

    output                              out_ready,
    output [LNN[0]-1:0][BitSize-1:0]    out_data,
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
        for (i = 0; i < NumLayers; i = i + 1) begin : layer
            logic nl_out_ready;
            logic nl_out_valid;
            logic nl_out_done;
            logic nl_out_start;

            logic nl_in_ready;
            logic nl_in_valid;
            logic nl_in_done;
            logic nl_in_start;

            if (i < NumLayers - 1) begin
                always_ff @(posedge clk) begin
                    nl_in_ready    <= nl_out_ready;
                    nl_in_valid    <= nl_out_valid;
                    nl_in_done     <= nl_out_done;
                    nl_in_start    <= nl_out_start;
                    nl_in          <= nl_out;
                end
            end
            
            logic [LNN[NumLayers-1-i]-1:0][BitSize-1:0] nl_out;
            logic [LNN[NumLayers-1-i]-1:0][BitSize-1:0] nl_in;
            if (i == 0) begin
                // out_ready can be used to signal which array has not been loaded yet
                systolic_array #(.BitSize(BitSize), .Weight_BitSize(LWB[NumLayers-1-i]), .M_W_BitSize(M_W_BitSize), .NumOfInputs(ImageSize), .NumOfNerves(LNN[NumLayers-1-i])) 
                    layer1 (.clk(clk), .res_n(res_n), .in_valid(fl_out_valid_p), .in_start(fl_out_start_p), .in_data(fl_out_data_p), //.in_w_en(in_w_en), 
                    .in_weights(in_weights[MaxNumNerves-1:MaxNumNerves-LNN[NumLayers-1-i]]), .in_partial_sum('0 /*in_partial_sum*/), 
                    .out_ready(nl_out_ready), .out_valid(nl_out_valid), .out_done(nl_out_done), .out_data(nl_out), .out_start(nl_out_start));

            end
            else begin
                systolic_array #(.BitSize(BitSize), .Weight_BitSize(LWB[NumLayers-1-i]), .M_W_BitSize(M_W_BitSize), .NumOfInputs(LNN[NumLayers-i]), .NumOfNerves(LNN[NumLayers-1-i])) 
                    layer1 (.clk(clk), .res_n(weight_en_posedge[NumLayers-1-i]), .in_valid(layer[i-1].nl_in_valid || layer[i-1].nl_in_done), .in_start(layer[i-1].nl_in_start), .in_data(layer[i-1].nl_in), //.in_w_en(in_w_en), 
                    .in_weights(in_weights[MaxNumNerves-1:MaxNumNerves-LNN[NumLayers-1-i]]), .in_partial_sum('0 /*in_partial_sum*/), 
                    .out_ready(nl_out_ready), .out_valid(nl_out_valid), .out_done(nl_out_done), .out_data(nl_out), .out_start(nl_out_start));

            end

            logic temp_out_ready;

            if (i == 0) begin
                assign temp_out_ready = nl_in_ready;
            end
            else begin
                assign temp_out_ready = nl_out_ready & layer[i-1].temp_out_ready;
            end

        end
        assign out_ready    = layer[NumLayers-1].temp_out_ready & fl_out_ready;
        assign out_valid    = layer[NumLayers-1].nl_out_valid;
        assign out_data     = layer[NumLayers-1].nl_out;
        assign out_done     = layer[NumLayers-1].nl_out_done;
    endgenerate

    
endmodule