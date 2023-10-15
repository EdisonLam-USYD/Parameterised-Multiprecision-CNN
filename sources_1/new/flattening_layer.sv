`timescale 1ns / 1ps
// flattening layer, compatible inputs include: pooling layer(s), convolution stage (and switches)
// Explaining the parameters:
// Number of Images -> number of input images and therefore number of flattening PEs required - outputs (NOT NUMBER OF INPUTs necessarily)
// Number of Processing Elements per Input - determines number of outputs per conv/pooling stage
//
// Asumption made during the creation of this module is that the in_valid for each conv is already determined by an intermediary switch (if conv stage is connected to this)

// flattening_layer #(.BitSize(), .ImageSize(), .NumOfImages(), .NumOfInputs(), .CyclesPerPixel())
// f_layer0 (.clk(), .res_n(), .in_valid(), .in_data(), .out_ready(), .out_valid(), .out_data())
module flattening_layer #(BitSize = 2, ImageSize = 9, NumOfImages = 4, NumOfInputs = 2, CyclesPerPixel = 4)
(
    input clk,
    input res_n,
    input [NumOfImages-1:0]                 in_valid,
    input [NumOfInputs-1:0][BitSize-1:0]                    in_data,
    // input [NumOfImages-1:0]                 done_check_c,

    output logic                              out_ready,  // always ready?
    output logic                              out_valid,
    output logic                              out_start,
    output logic [ImageSize-1:0][BitSize-1:0] out_data
);


logic [NumOfImages-1:0] done_check_r; // if all are done, then out_ready = 0
logic [NumOfImages-1:0] done_check_c;
logic [$clog2(ImageSize)+1:0] counter_tot_c_c; // total cycles
logic [$clog2(ImageSize)+1:0] counter_tot_c_r;
logic [$clog2(CyclesPerPixel):0] counter_cycles_c; // individual clock cycles for out_valid
logic [$clog2(CyclesPerPixel):0] counter_cycles_r;
logic out_ready_c;
logic start_latch;

logic [ImageSize-1:0][BitSize-1:0] tot_agent [NumOfImages-1:0];

genvar i;
generate 
    for (i = 0; i < NumOfImages; i = i + 1) begin : gen_PEs
        logic [ImageSize-1:0][BitSize-1:0] out;

        wire [BitSize-1:0] in_fpe;

        // assign in_fpe = (!done_check_r[NumOfImages-1-i] && out_ready) ? in_data[NumOfInputs-1-(i%NumOfInputs)] : BitSize'(0);
        assign in_fpe = (out_ready) ? in_data[NumOfInputs-1-(i%NumOfInputs)] : BitSize'(0);

        flattening_pe #(.BitSize(BitSize), .ImageSize(ImageSize), .Delay(i)) flat_pe 
            (.clk(clk), .res_n(res_n), .in_valid(in_valid[NumOfImages-1-i] || !out_ready), .in_data(in_fpe), .out_data(out), .out_done(done_check_c[NumOfImages-1-i]));
        // in_valid[NumOfImages-1-i] || done_check_r[NumOfImages-1-i]  --  for in_valid  -- wrong for now
        

        assign tot_agent[i] = gen_PEs[i].out;
    end
endgenerate

always@(*) begin
    out_data = '0;
    for (int i = 0; i < NumOfImages; i = i + 1) begin
        out_data = out_data | tot_agent[i];
    end
end

always_comb
begin
    // out_data = tot_agent.or(); // not synthesisable

    out_valid = 0;
    out_ready_c = 1;
    counter_tot_c_c = counter_tot_c_r;
    counter_cycles_c = counter_cycles_r;
    out_start = 0;
    if (in_valid != 0)
    begin
        

        if (counter_cycles_c == CyclesPerPixel - 1) begin
            counter_tot_c_c = counter_tot_c_c + 1;
            out_valid = 1;
            out_start = (start_latch) ? 0 : 1;
        end
        counter_cycles_c = (counter_cycles_c < CyclesPerPixel - 1) ? counter_cycles_c + 1 : 0;
        if (counter_tot_c_c >= ImageSize || start_latch) begin
            // should be done
            // all pixels should have been given by this point  
            out_ready_c = 0;
        end
    end
    else if (!out_ready) begin // turn into 1 cycle per pixel after all inputs are taken
        counter_tot_c_c = counter_tot_c_c + 1;
        out_valid = (counter_tot_c_c != ImageSize + 1) ? 1 : 0;
        // out_start = (counter_tot_c_c != ImageSize + 1 && ) ? 0;
        out_start = (out_valid && !start_latch) ? 1 : 0;
    end
end

always_ff @(posedge clk) 
begin
    if (!res_n)
    begin
        done_check_r        <= '0;
        counter_tot_c_r     <= 0;
        counter_cycles_r    <= 0;
        out_ready           <= 1;
        start_latch         <= 0;
    end
    else
    begin
        out_ready = out_ready_c & out_ready;
        done_check_r = done_check_c | done_check_r;
        counter_tot_c_r = counter_tot_c_c;
        counter_cycles_r = counter_cycles_c;
        start_latch <= (counter_tot_c_c > NumOfImages) ? 1 : start_latch;

    end
end

endmodule