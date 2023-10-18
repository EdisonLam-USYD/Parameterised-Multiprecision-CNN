`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2023 18:08:00
// Design Name: 
// Module Name: stolic_pe
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

module sys_sum #(BitSize = 8, NumOfNerves = 4, DepthIn = 2) (
    input clk,
    input res_n,
    input in_valid,
    input in_start,
    input [NumOfNerves-1:0][BitSize-1:0] in_data,
    
    output logic out_start,
    output logic out_valid,
    output logic [BitSize-1:0] out_data
    );

    logic [NumOfNerves-1:0][BitSize-1:0] totals_r;
    logic [NumOfNerves-1:0][BitSize-1:0] totals_c;

    logic [$clog2(NumOfNerves+1):0]   pos_counter_r;
    logic [$clog2(NumOfNerves+1):0]   pos_counter_c;
    logic [$clog2(DepthIn+1):0]       row_counter_r;
    logic [$clog2(DepthIn+1):0]       row_counter_c;
    
    always_ff @( posedge clk ) begin
        if (!res_n) begin
            pos_counter_r   <= '0;
            row_counter_r   <= '0;
            totals_r        <= '0;

        end 
        else begin
            pos_counter_r   <= pos_counter_c;
            row_counter_r   <= row_counter_c;
            totals_r        <= (pos_counter_c != NumOfNerves) ? totals_c : '0;
        end
    end

    

    always_comb begin
        pos_counter_c = pos_counter_r;
        row_counter_c = row_counter_r;
        totals_c = totals_r;
        out_valid = 0;
        out_data = '0;
        out_start = 0;

        if (in_valid) begin
            for (int i = 0; i < NumOfNerves; i = i + 1) begin
                totals_c[i] = totals_c[i] + in_data[i]; // by doing this, overflow of data should not occur (versus using totals_c + in_data)
            end
            
            if (in_start) begin
                row_counter_c = row_counter_c + 1;
                if (row_counter_c > DepthIn + 1) begin
                    row_counter_c = 0;
                    pos_counter_c = 0;
                end
            end
            if (row_counter_r == DepthIn && pos_counter_r < NumOfNerves) begin
                out_data = totals_r[NumOfNerves - pos_counter_c - 1];
                pos_counter_c = pos_counter_c + 1;
                out_valid = 1;
                out_start = (pos_counter_r == 0) ? 1 : 0;
            end
        end

    end

endmodule