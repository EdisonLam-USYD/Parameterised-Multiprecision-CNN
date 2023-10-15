`timescale 1ns / 1ps
// takes the in_data on the same cycle as the res_n (assuming in_valid is high)

// flattening_pe #(.BitSize(), .ImageSize(), .Delay()) flat_pe 
//     (.clk(), .res_n(), .in_valid(), .in_data(), .out_data(), .out_done());
module flattening_pe #(BitSize = 2, ImageSize = 9, Delay = 0) 
    (
        input clk,
        input res_n,
        input in_valid,
        input [BitSize-1:0] in_data,

        // output logic                                        out_ready, // does not seem necessary
        output logic [ImageSize-1:0][BitSize-1:0] out_data,
        output logic out_done       // not sure if needed
    );

    logic [$clog2(ImageSize + Delay + 1)-1:0] counter_r;
    logic [$clog2(ImageSize + Delay + 1)-1:0] counter_c;

    // logic [ImageSize-1:0][BitSize-1:0] out_data_c;
    logic [BitSize-1:0] in_data_c;
    logic done_latch;
    

    always_comb begin
        counter_c = counter_r;
        out_done = 0;
        out_data = '0;
        if (counter_c >= Delay) out_data[ImageSize-counter_c+Delay] =  in_data_c; // include if changing variables after clock posedge
        if (in_valid)
        begin
            // counter_c = (ImageSize - 1 != counter_r) ? counter_r + 1 : 0;
            // out_data = '0;
            // if (counter_c >= Delay) out_data[ImageSize-counter_c+Delay] =  in_data_c;
            counter_c = counter_r + 1;
            // if (counter_c >= Delay) out_data[ImageSize-counter_c+Delay] =  in_data_c;
            out_done = ((counter_c >= ImageSize + Delay) && !done_latch) ? 1 : 0;
        end
        // else if (counter_c >= Delay) begin
        //     out_data = '0;
        //     out_data[ImageSize-counter_c+Delay] =  in_data_c;
        // end
    end

    always_ff @(posedge clk) begin
        if (!res_n)
        begin
            counter_r <= 0;
            done_latch <= 0;
        end
        else
        begin
            counter_r <= counter_c;
            done_latch <= (out_done) ? 1 : done_latch;
        end
    end

    genvar i;
    generate
        if (Delay == 0)
            assign in_data_c = (in_valid) ? in_data : in_data_c;
        else 
        begin
            for (i = 0; i <= Delay; i = i + 1)
            begin : s_del
                logic [BitSize-1:0] buffer;

                if (i == 0)
                begin
                    always_ff @(posedge clk) 
                    begin
                        if (!res_n) s_del[0].buffer <= '0;
                        else
                        begin
                            if (in_valid) s_del[0].buffer <= in_data;
                        end
                    end
                end
                else
                begin
                    always_ff @(posedge clk) 
                    begin
                        if (!res_n) s_del[i].buffer <= '0;
                        else
                        begin
                            if (in_valid) s_del[i].buffer <= s_del[i-1].buffer;
                        end
                    end
                end
            end 
            assign in_data_c = s_del[Delay].buffer; // may need to make it Delay - 1 depending on TB
        end
    endgenerate

endmodule