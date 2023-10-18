module TB_conv_pooling_top;

    localparam BitSize = 8;
    localparam N = 3;
    localparam ImageWidth = 8;
    localparam Stride = 2;
    //localparam K = 2;
    //localparam NoK = 4;
    //localparam CyclesPerPixel = 2;
    // localparam ProcessingElements = NoK/CyclesPerPixel;

    
    localparam C1CyclesPerPixel = 2;
    localparam C1NumberOfK      = 4;
    localparam C1KernelBitSize  = 2;
    
    localparam C2CyclesPerPixel = 4;
    localparam C2NumberOfK      = 8;
    localparam C2KernelBitSize  = 4;
    localparam C2ProcessingElements = 2;


    localparam [C1KernelBitSize*(N*N)-1:0] C1kernel [C1NumberOfK-1:0]
                        = {18'b000110110001101100,
                           18'b111111101010010101,
                           18'b111111101010010101,
                           18'b110100100011001011};
        
    // localparam [C2KernelBitSize*(N*N)-1:0] C2kernel [C2NumberOfK-1:0] 
    //                     = {18'b000110110001101100,
    //                        18'b111111101010010101,
    //                        18'b110100100011001011,
    //                        18'b101010010101011000}; 

    localparam [C2KernelBitSize*(N*N)-1:0] C2kernel [C2NumberOfK-1:0]
                        = {36'b001011000010101010010011101110001111,
                           36'b110101000010011100011100000010110010,
                           36'b010000010011001110110110001010001100,
                           36'b100110111000111111101111100100100010,
                           36'b101111010111101011010011101101001001,
                           36'b001110110011000011110111110010010011,
                           36'b111101101101111101100100111110101100,
                           36'b110101111110110010011111001100101101};
       
    // localparam [C4KernelBitSize*(N*N)-1:0] C4kernel [C4NumberOfK-1:0]
    //                     = {72'b101000000010011001000010111111101100111010010100000010011000011000011100,
    //                        72'b000000100101111101000010011010001001100100111010101000001011001011111101,
    //                        72'b011101001111110110100111110111010001110001110110010100101010110001101100,
    //                        72'b001111010110111100101010100001011100010010000010011001100101111100010001};




    logic                                           clk;
    logic                                           res_n;
    logic                                           in_valid;
    logic [BitSize-1:0]                             in_data;
    logic                                           out_ready;
    
    logic [C2NumberOfK-1:0]                                     C2_out_valid;
    logic [C2ProcessingElements-1:0][BitSize-1:0]       C2_out_data;
    //logic [C3NumberOfK-1:0]                                     C3_out_valid;
    //logic [C3NumberOfK-1:0][BitSize-1:0]       C3_out_data;
    //logic [C4NumberOfK-1:0]                                     C4_out_valid;
    //logic [C4NumberOfK-1:0][BitSize-1:0]       C4_out_data;        

    logic [ImageWidth*ImageWidth-1:0][BitSize-1:0]  test_image;
    logic [BitSize-1:0]                             a;
    logic [BitSize-1:0]                             b;
    logic [BitSize-1:0]                             c;
    logic [BitSize-1:0]                             d;

    // logic [C1NumberOfK-1:0][N-1:0][N-1:0][C1KernelBitSize-1:0] C1kernel;
    // logic [C2NumberOfK-1:0][N-1:0][N-1:0][C2KernelBitSize-1:0] C2kernel;
    // logic [C3NumberOfK-1:0][N-1:0][N-1:0][C3KernelBitSize-1:0] C3kernel;    
    // logic [C4NumberOfK-1:0][N-1:0][N-1:0][C4KernelBitSize-1:0] C4kernel;



    conv_pooling_top #(.N(N), .BitSize(BitSize), .ImageWidth(ImageWidth), .Stride(Stride),
        .C1CyclesPerPixel(C1CyclesPerPixel), .C2CyclesPerPixel(C2CyclesPerPixel),
        .C1NumberOfK(C1NumberOfK), .C2NumberOfK(C2NumberOfK), .C2ProcessingElements(C2ProcessingElements),
        .C1KernelBitSize(C1KernelBitSize), .C2KernelBitSize(C2KernelBitSize), 
        .C1kernel(C1kernel), .C2kernel(C2kernel)) conv_pooling_top
		(
    		.clk(clk),
            .res_n(res_n),
        	.in_valid(in_valid),
            .in_data(in_data),
            .out_ready(out_ready),
            .out_valid(C2_out_valid),
            .out_data(C2_out_data)
    );

    // conv_pooling_top #(.N(N), .BitSize(BitSize), .ImageWidth(ImageWidth), .C1CyclesPerPixel(C1CyclesPerPixel), .Stride(Stride), 
    //     .C2NumberOfK(C2NumberOfK), .C3NumberOfK(C3NumberOfK), .C4NumberOfK(C4NumberOfK),
    //     .C1KernelBitSize(C1KernelBitSize), .C2KernelBitSize(C2KernelBitSize), .C3KernelBitSize(C3KernelBitSize), .C4KernelBitSize(C4KernelBitSize),
    //     .C1kernel(C1kernel), .C2kernel(C2kernel), .C3kernel(C3kernel), .C4kernel(C4kernel)) conv_pooling_top
	// 	(
    // 		.clk(clk),
    //         .res_n(res_n),
    //     	.in_valid(in_valid),
    //         .in_data(in_data),
    //         .out_ready(out_ready),
    //         .C2_out_valid(C2_out_valid),
    //         .C2_out_data(C2_out_data),
    //         .C3_out_valid(C3_out_valid),
    //         .C3_out_data(C3_out_data),
    //         .C4_out_valid(C4_out_valid),
    //         .C4_out_data(C4_out_data)
    // );



    
    initial
    begin
        // $monitor("@ %0t:\n\t\t%b %b\n %b", $time);
        a = 4'b01110111;
        b = 4'b00100010;
        c = 4'b11111111;
        d = 4'b10001000;
        test_image =   {a, b, b, c, b, c, a, c,
                        d, d, c, a, c, a, b, c,
                        c, b, d, d, d, d, d, a,
                        b, a, b, c, d, a, d, c,
                        c, d, d, d, d, d, a, d,
                        d, d, c, a, c, a, c, a,
                        c, b, d, d, d, d, b, c,
                        b, b, c, c, a, d, c, b};
        res_n = 0;
        clk = 1;
        #2
        res_n = 1;
        clk = 0;
      


        for (int counter = 1; counter <= ImageWidth*ImageWidth*8; counter = counter) begin
            #10
            clk = 1;
            if(counter <= ImageWidth*ImageWidth) begin
                in_data = test_image[ImageWidth*ImageWidth - counter];
                in_valid = 1;
            end
            else begin
                in_data = '0;
                in_valid = '0;
            end
            #10
            clk = 0;
            if (out_ready) begin
                counter = counter + 1;
            end
          
        end
    end


endmodule