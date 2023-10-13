`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2023 18:17:11
// Design Name: 
// Module Name: multiply_1Bit
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

// i_prod = 1 -> * 1
// i_prod = 0 -> * -1
module multiply_1Bit #(BitSize = 32)
    (
    input signed [BitSize-1:0] in_data,
    input i_prod,
    output logic [BitSize-1:0] out_data
    );
    
    always_comb begin
        if (i_prod) begin
            out_data = in_data;
        end 
        else begin
            out_data = ~in_data + 1;
        end
    end
endmodule
