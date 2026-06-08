// =============================================================================
// gift64_round.v
// One GIFT-64 round, fully combinational. Reused for 28 cycles by the core.
//
// Round function (in canonical order, NOT the same as Dipper's):
//   1. SubCells       : 16 parallel GIFT S-boxes
//   2. PermBits       : GIFT-64 BOGI bit permutation
//   3. AddRoundKey    : XOR U into bits {4i+1}, V into bits {4i}
//                       (U and V are the upper and lower 16 bits of the
//                        32-bit round key, respectively)
//   4. AddRoundConst  : XOR 1 into b63;
//                       XOR rc[0..5] into bits {3, 7, 11, 15, 19, 23}
//
// rkey layout: rkey[31:16] = U, rkey[15:0] = V.
// =============================================================================
`default_nettype none

module gift64_round (
    input  wire [63:0] state_in,
    input  wire [31:0] rkey,        // {U, V} = {k1, k0}
    input  wire [ 5:0] rc,
    output wire [63:0] state_out
);
    // ---- Step 1: SubCells (16 parallel GIFT S-boxes) ----
    wire [63:0] s_sub;
    genvar j;
    generate
        for (j = 0; j < 16; j = j + 1) begin : sbox_layer
            gift_sbox u_sbox (
                .x (state_in[4*j +: 4]),
                .y (s_sub  [4*j +: 4])
            );
        end
    endgenerate

    // ---- Step 2: PermBits ----
    wire [63:0] s_perm;
    gift64_perm u_perm (
        .din  (s_sub),
        .dout (s_perm)
    );

    // ---- Step 3 + 4: AddRoundKey + AddRoundConstant in one XOR layer ----
    // Build a 64-bit mask, then XOR once.
    wire [15:0] U = rkey[31:16];
    wire [15:0] V = rkey[15: 0];

    wire [63:0] arkmask;
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : ark_pack
            assign arkmask[4*k    ] = V[k];      // b_{4k}   ^= V[k]
            assign arkmask[4*k + 1] = U[k];      // b_{4k+1} ^= U[k]
            assign arkmask[4*k + 2] = 1'b0;
            assign arkmask[4*k + 3] = 1'b0;
        end
    endgenerate

    // Round constant injection mask: b63=1, b{3,7,11,15,19,23} = rc[0..5]
    wire [63:0] rcmask;
    assign rcmask[ 3]   = rc[0];
    assign rcmask[ 7]   = rc[1];
    assign rcmask[11]   = rc[2];
    assign rcmask[15]   = rc[3];
    assign rcmask[19]   = rc[4];
    assign rcmask[23]   = rc[5];
    assign rcmask[63]   = 1'b1;
    // Fill the remaining bits with 0
    assign rcmask[ 2: 0] = 3'b000;
    assign rcmask[ 6: 4] = 3'b000;
    assign rcmask[10: 8] = 3'b000;
    assign rcmask[14:12] = 3'b000;
    assign rcmask[18:16] = 3'b000;
    assign rcmask[22:20] = 3'b000;
    assign rcmask[62:24] = 39'b0;

    assign state_out = s_perm ^ arkmask ^ rcmask;
endmodule

`default_nettype wire
