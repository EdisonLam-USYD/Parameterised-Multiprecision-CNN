`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Edison Lam
// 
// Create Date: 18.10.2023 18:08:00
// Design Name: 
// Module Name: sys_stacker
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

// NumOfNerves must be divisible by Depth
// input to this module should be the sys_sum module

module sys_stacker #(BitSize = 8, NumOfNerves = 4, DepthOut = 2) (
    input clk,
    input res_n,
    input in_valid,
    input in_start,
    input [NumOfNerves-1:0][BitSize-1:0] in_data,

    output logic out_start,
    output logic out_valid,
    output logic [(NumOfNerves/DepthOut)-1:0][BitSize-1:0] out_data
);

localparam OUT_WIDTH = (NumOfNerves/DepthOut);

logic [$clog2(OUT_WIDTH):0] pos_counter_c;
logic [$clog2(OUT_WIDTH):0] pos_counter_r;

always_ff @(posedge clk) begin
    if (!res_n) begin
        pos_counter_r <= '0;
    end
    else begin
        pos_counter_r <= pos_counter_c;
    end
end

always_comb begin
    out_start = 0;
    out_valid = 0;
    out_data  = '0;
    pos_counter_c = pos_counter_r;
    if (in_valid) begin
        out_valid = 1;
        pos_counter_c = (in_start) ? 0 : (pos_counter_c + 1) % OUT_WIDTH;
        out_start = (pos_counter_c == 0) ? 1 : 0;
        out_data[OUT_WIDTH - 1 - pos_counter_c] = in_data;
    end
end

endmodule