// SPECK-64/128 round-based core (one round/cycle, on-the-fly key schedule)
module speck_core_128 (
    input              clk,
    input              rst,
    input              start,
    input      [63:0]  pt,    // {x, y}
    input      [127:0] key,   // {kw0,kw1,kw2,kw3}, kw0 = MSW
    output reg [63:0]  ct,
    output reg         done
);
    localparam R = 27;
    reg [31:0] x, y, k, l0, l1, l2;
    reg [4:0]  cnt;
    reg        busy;

    function [31:0] rotr8; input [31:0] v; rotr8 = {v[7:0],  v[31:8]};  endfunction
    function [31:0] rotl3; input [31:0] v; rotl3 = {v[28:0], v[31:29]}; endfunction

    wire [31:0] rk = k;
    wire [31:0] nx = (rotr8(x) + y) ^ rk;
    wire [31:0] ny = rotl3(y) ^ nx;
    wire [31:0] nl = (rotr8(l0) + k) ^ {27'b0, cnt};
    wire [31:0] nk = rotl3(k) ^ nl;

    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; end
        else if (start) begin
            x<=pt[63:32]; y<=pt[31:0];
            k<=key[31:0]; l0<=key[63:32]; l1<=key[95:64]; l2<=key[127:96];
            cnt<=0; busy<=1; done<=0;
        end else if (busy) begin
            x<=nx; y<=ny;
            k<=nk; l0<=l1; l1<=l2; l2<=nl;
            cnt<=cnt+1;
            if (cnt==R-1) begin busy<=0; done<=1; ct<={nx,ny}; end
        end
    end
endmodule
