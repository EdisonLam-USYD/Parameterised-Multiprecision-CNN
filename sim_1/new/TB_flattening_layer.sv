// Note: when using the flattening layer, for the cycles per pixel, the module must receive N number of non-zero invalids to return a valid out_data
// may need a separate enable signal which can act in if data in is not steady




module TB_flattening_layer;
    localparam BitSize          = 4;
    localparam ImageSize        = 4; // i.e. NxN
    localparam NumOfImages      = 4;
    localparam NumOfPEPerInput  = 1;
    localparam NumOfInputs      = 2;
    localparam CyclesPerPixel   = 2;

    logic clk;
    logic res_n;
    logic [NumOfImages-1:0] in_valid;
    logic [NumOfInputs*NumOfPEPerInput-1:0][BitSize-1:0] in_data;

    logic out_ready;
    logic out_valid;
    logic [ImageSize-1:0][BitSize-1:0] out_data;

    logic [NumOfImages-1:0][ImageSize-1:0][BitSize-1:0] inputs;
    logic [ImageSize-1:0][BitSize-1:0] a;
    logic [ImageSize-1:0][BitSize-1:0] b;
    logic [ImageSize-1:0][BitSize-1:0] c;
    logic [ImageSize-1:0][BitSize-1:0] d;
    
    flattening_layer #(.BitSize(BitSize), .ImageSize(ImageSize), .NumOfImages(NumOfImages), 
        .NumOfInputs(NumOfInputs), .CyclesPerPixel(CyclesPerPixel))
        f_layer0 (.clk(clk), .res_n(res_n), .in_valid(in_valid), .in_data(in_data), 
        .out_ready(out_ready), .out_valid(out_valid), .out_data(out_data));

    int j;
    int i;
    
    // assign in_valid = {(j % 2) == CyclesPerPixel}
 
    initial 
    begin
        a = {BitSize'(4), BitSize'(4), BitSize'(4), BitSize'(4)};
        b = {BitSize'(3), BitSize'(3), BitSize'(3), BitSize'(3)};
        c = {BitSize'(2), BitSize'(2), BitSize'(2), BitSize'(2)};
        d = {BitSize'(1), BitSize'(1), BitSize'(1), BitSize'(1)};
        inputs = {a, b, c, d};

        res_n = 0;
        clk = 0;
        #5
        clk = 1;
        in_valid = 0;
        #5
        res_n = 1;
        clk = 0;

        $monitor("@%0t: out = %p, %p -> %b", $time, out_data, f_layer0.tot_agent, f_layer0.tot_agent.or());

        for (i = 0; i < ImageSize; i = i + 1) begin
            for (j = 0; j < CyclesPerPixel; j = j + 1) begin
                #10
                if (j == 0) in_valid = {1'b1, 1'b1, 1'b0, 1'b0};
                else if (j == 1) in_valid = {1'b0, 1'b0, 1'b1, 1'b1};
                else in_valid = '0;
                in_data = {inputs[(j % NumOfImages)][ImageSize - i - 1], inputs[((j + 2) % NumOfImages)][ImageSize - i - 1]};
                clk = 1;
                #10
                clk = 0;
            end
        end
        for (i = 0; i < ImageSize; i = i + 1) begin
            for (j = 0; j < CyclesPerPixel; j = j + 1) begin
                #10
                if (j == 0) in_valid = {1'b1, 1'b1, 1'b0, 1'b0};
                else if (j == 1) in_valid = {1'b0, 1'b0, 1'b1, 1'b1};
                else in_valid = '0;
                in_data = '0;
                clk = 1;
                #10
                clk = 0;
            end
        end
    end
endmodule