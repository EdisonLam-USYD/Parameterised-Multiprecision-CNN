`timescale 1ns / 1ps

// Max bitsize = bram width = 32 but can be changed

//Designed for specifically Processing elemets = 2
module mem_module #(NumberOfK = 4, BitSize = 32, ProcessingElements = 2, ImageWidth = 4)
    (
        input                   clk,
        input                   res_n,
        input                   pooling_done,
        input [NumberOfK-1:0]   in_valid,
        input [ProcessingElements-1:0][BitSize-1:0] in_data,
        output logic [BitSize-1:0] out_data,  
        output logic                out_valid,
        output logic                image_done
    );

    localparam TotalPixels = (ImageWidth**2);
    localparam ZEROS = 32 - BitSize;

    logic [31:0] addra;
    logic [31:0] addrb;

    integer kernel_count_c;
    integer kernel_count_r;

    integer pixel_count_c;
    integer pixel_count_r;

    logic [3:0] wea;
    logic [3:0] web;

    logic read_mode_c;
    logic read_mode_r;

    logic image_done_r;

    integer tempA;
    integer tempB;

    logic pooling_done_r;
    

    integer i;
    always_comb
    begin
        tempA = {32{1'b0}};
        tempB = {32{1'b0}};
        for(i = 0; (i < NumberOfK); i = i + 2) begin
            tempA = tempA|((in_valid[i])?i:{32{1'b0}});
            tempB = tempB|((in_valid[i+1])?(i+1):{32{1'b0}});
        end
    end




    assign addra = (!read_mode_r)?(tempA*(ImageWidth**2) + pixel_count_r):{{32{1'b0}},pixel_count_r};
    assign addrb = tempB * (ImageWidth**2) + pixel_count_r;



    blk_mem_gen_0 bram (
        .clka(clk),             // input wire clka
        .rsta(!res_n),            // input wire rsta
        .ena(1'b1),              // input wire ena - read enable
        .wea(wea),              // input wire [3 : 0] wea - write enable
        .addra(addra),          // input wire [31 : 0] addra
        .dina({{ZEROS{1'b0}},in_data[0]}),  // input wire [31 : 0] dina
        .douta(out_data),          // output wire [31 : 0] douta
        .clkb(clk),             // input wire clkb
        .rstb(!res_n),            // input wire rstb
        .enb(1'b1),              // input wire enb
        .web(web),              // input wire [3 : 0] web
        .addrb(addrb),          // input wire [31 : 0] addrb
        .dinb({{ZEROS{1'b0}},in_data[1]}),  // input wire [31 : 0] dinb
        .doutb(),          // output wire [31 : 0] doutb
        .rsta_busy(),  // output wire rsta_busy
        .rstb_busy()   // output wire rstb_busy
    );


    always_comb
    begin
        image_done = image_done_r;
        wea = 4'b0000;
        web = 4'b0000;
        out_valid = 0;
        kernel_count_c = kernel_count_r;
        pixel_count_c = pixel_count_r;
        read_mode_c = read_mode_r;

        if(read_mode_c == 0)
        begin
            if (in_valid != '0) 
            begin
                wea = 4'b1111;
                web = 4'b1111;
                kernel_count_c = (kernel_count_c + ProcessingElements)%NumberOfK;
                if(kernel_count_c == 0)
                begin
                    pixel_count_c = pixel_count_c + 1;
                end
                if(pixel_count_c >= TotalPixels)
                begin
                    pixel_count_c = 0;
                    read_mode_c = 1;
                    out_valid  = 1;
                    image_done = 0;
                end
            end
        end
        else
        begin
            if(pixel_count_c < TotalPixels*NumberOfK)
            begin
                if((pixel_count_c+1)%(TotalPixels) == 0 && pooling_done_r==0)// && pixel_count_c!=0)
                begin
                    image_done = 1;
                    out_valid = 0;
                end
                else
                begin
                    pixel_count_c = pixel_count_c + 1;
                    out_valid = 1;
                    image_done = 0;
                end
            end
        end        
    end


    always_ff@(posedge clk) begin
    	if(!res_n)
      	begin
            kernel_count_r <= 0;
            pixel_count_r <= 0;
            read_mode_r <= 0;
            image_done_r <= 1;
            pooling_done_r <= 0;
      	end
    	else
      	begin
            kernel_count_r <= kernel_count_c;
            pixel_count_r  <= pixel_count_c;
            read_mode_r <= read_mode_c;
            image_done_r <= image_done;
            pooling_done_r <= pooling_done;
        end
  	end
endmodule