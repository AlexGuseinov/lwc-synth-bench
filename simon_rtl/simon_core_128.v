// SIMON-64/128 round-based core (z3, one round/cycle, on-the-fly key schedule)
module simon_core_128 (
    input              clk,
    input              rst,
    input              start,
    input      [63:0]  pt,    // {x, y}
    input      [127:0] key,   // {kw0,kw1,kw2,kw3}, kw0 = MSW
    output reg [63:0]  ct,
    output reg         done
);
    localparam R = 44;
    localparam [31:0] C = 32'hFFFFFFFC;
    localparam [61:0] Z3 = 62'b11011011101011000110010111100000010010001010011100110100001111;
    reg [31:0] x, y, k0, k1, k2, k3;
    reg [5:0]  cnt;
    reg        busy;

    function [31:0] rotl1; input [31:0] v; rotl1 = {v[30:0], v[31]};    endfunction
    function [31:0] rotl2; input [31:0] v; rotl2 = {v[29:0], v[31:30]}; endfunction
    function [31:0] rotl8; input [31:0] v; rotl8 = {v[23:0], v[31:24]}; endfunction
    function [31:0] rotr3; input [31:0] v; rotr3 = {v[2:0],  v[31:3]};  endfunction
    function [31:0] rotr1; input [31:0] v; rotr1 = {v[0],    v[31:1]};  endfunction

    wire        zbit = Z3[61-cnt];
    wire [31:0] tmp  = rotr3(k3) ^ k1;
    wire [31:0] tmp2 = tmp ^ rotr1(tmp);
    wire [31:0] nk4  = k0 ^ tmp2 ^ {31'b0, zbit} ^ C;
    wire [31:0] nx   = y ^ (rotl1(x) & rotl8(x)) ^ rotl2(x) ^ k0;
    wire [31:0] ny   = x;

    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; end
        else if (start) begin
            x<=pt[63:32]; y<=pt[31:0];
            k0<=key[31:0]; k1<=key[63:32]; k2<=key[95:64]; k3<=key[127:96];
            cnt<=0; busy<=1; done<=0;
        end else if (busy) begin
            x<=nx; y<=ny;
            k0<=k1; k1<=k2; k2<=k3; k3<=nk4;
            cnt<=cnt+1;
            if (cnt==R-1) begin busy<=0; done<=1; ct<={nx,ny}; end
        end
    end
endmodule
