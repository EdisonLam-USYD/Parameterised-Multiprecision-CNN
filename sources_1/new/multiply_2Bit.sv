`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2023 18:17:11
// Design Name: 
// Module Name: multiply_2Bit
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


module multiply_2Bit #(BitSize = 32)
    (
    input [BitSize-1:0] in_data, // 32bit number
    input signed [1:0] i_prod, // in 2's complement
    output logic [BitSize-1:0] out_data
    );
    // 1st bit is signed bit, 2nd is whether it is 1 or 0
    assign out_data = (i_prod[0]) ? ((i_prod[1]) ? ~in_data+1 : in_data) : 0;
    // always_comb begin
    //     case (i_prod) 
    //         2'b00: out_data <= BitSize'('b0);
    //         2'b01: out_data <= in_data;
    //         2'b11: out_data <= ~in_data + 1; // -1
    //         2'b10: out_data <= (~in_data + 1) << 1; // -2
    //     endcase
    // end
endmodule
