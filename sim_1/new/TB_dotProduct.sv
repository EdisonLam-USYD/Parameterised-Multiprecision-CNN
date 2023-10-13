`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.03.2023 18:33:34
// Design Name: 
// Module Name: TB_dotProduct
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

`define B 4
`define N 3
`define K 1


module TB_dotProduct;

    logic [`K*(`N*`N)-1:0] in_kernel;
    logic [`B*(`N*`N)-1:0] in_conv;
   
    logic [`B*(`N*`N)-1:0] out;
    logic [`B-1:0] max;
    logic [`B-1:0] sum;
    
    logic [`B-1:0] a, b, c;

    assign in_conv = {{a,b,c},{b,c,a},{c,a,b}};
    
    initial begin
        $monitor("in = %d,  kern = %d   out = %d\nin = %d,  kern = %d   out = %d\nin = %d,  kern = %d   out = %d\nSum: %d\nMax was found to be: %d", 
            $signed(test1.i_data_layers[`N*`N-1:`N*`N-`N]), test1.kernel_layers[`N*`N-1:`N*`N-`N], $signed(test1.o_data_layers[`N*`N-1:`N*`N-`N]),
            $signed(test1.i_data_layers[`N*`N-`N-1:`N*`N-2*`N]), test1.kernel_layers[`N*`N-`N-1:`N*`N-2*`N], $signed(test1.o_data_layers[`N*`N-`N-1:`N*`N-2*`N]),
            $signed(test1.i_data_layers[`N-1:0]), test1.kernel_layers[`N-1:0], $signed(test1.o_data_layers[`N-1:0]), $signed(sum), $signed(max));
        
        a = `B'b1100; 
        b = `B'b0100;
        c = `B'b0010;

        in_kernel = {3'b101, 3'b010, 3'b001};
        
        #10
        a = `B'b1111; 
        b = `B'b0110;
        c = `B'b1010;

    end
    
//    always @(*) begin
//        $display("in = %b,  kern = %b   out = %b", in_conv[17:12], in_kernel[8:6], out[17:12]);
//        $display("in = %b,  kern = %b   out = %b", in_conv[11:6], in_kernel[5:3], out[11:6]);
//        $display("in = %b,  kern = %b   out = %b", in_conv[5:0], in_kernel[2:0], out[5:0]);
//    end
    
    dot_NxN #(.N(`N), .BitSize(`B), .KernelBitSize(`K))     
        test1 (.kernel(in_kernel), .in_data(in_conv), .out_data(out), .sum(sum)); 
    max_pooling #(.N(`N), .BitSize(`B))
        test_max_pooling (.in_data(out), .out_data(max));
endmodule
