// =============================================================================
// gift128_round.v
// One GIFT-128 round, fully combinational. Reused for 40 cycles by the core.
//
// Round function:
//   1. SubCells       : 32 parallel GIFT S-boxes
//   2. PermBits       : GIFT-128 BOGI bit permutation
//   3. AddRoundKey    : XOR U (32 bits) into bits {4i+2},
//                       XOR V (32 bits) into bits {4i+1}
//   4. AddRoundConst  : XOR 1 into b127;
//                       XOR rc[0..5] into bits {3, 7, 11, 15, 19, 23}
//
// rkey layout: rkey[63:32] = U = k5||k4, rkey[31:0] = V = k1||k0.
// =============================================================================
`default_nettype none

module gift128_round (
    input  wire [127:0] state_in,
    input  wire [ 63:0] rkey,
    input  wire [  5:0] rc,
    output wire [127:0] state_out
);
    // ---- Step 1: SubCells (32 parallel GIFT S-boxes) ----
    wire [127:0] s_sub;
    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin : sbox_layer
            gift_sbox u_sbox (
                .x (state_in[4*j +: 4]),
                .y (s_sub  [4*j +: 4])
            );
        end
    endgenerate

    // ---- Step 2: PermBits ----
    wire [127:0] s_perm;
    gift128_perm u_perm (
        .din  (s_sub),
        .dout (s_perm)
    );

    // ---- Step 3 + 4: AddRoundKey + AddRoundConstant in one XOR layer ----
    wire [31:0] U = rkey[63:32];
    wire [31:0] V = rkey[31: 0];

    wire [127:0] arkmask;
    genvar k;
    generate
        for (k = 0; k < 32; k = k + 1) begin : ark_pack
            assign arkmask[4*k    ] = 1'b0;
            assign arkmask[4*k + 1] = V[k];      // b_{4k+1} ^= V[k]
            assign arkmask[4*k + 2] = U[k];      // b_{4k+2} ^= U[k]
            assign arkmask[4*k + 3] = 1'b0;
        end
    endgenerate

    // Round constant injection: b127=1, b{3,7,11,15,19,23} = rc[0..5]
    wire [127:0] rcmask;
    assign rcmask[  3] = rc[0];
    assign rcmask[  7] = rc[1];
    assign rcmask[ 11] = rc[2];
    assign rcmask[ 15] = rc[3];
    assign rcmask[ 19] = rc[4];
    assign rcmask[ 23] = rc[5];
    assign rcmask[127] = 1'b1;
    // Zero-fill the rest
    assign rcmask[  2:  0] = 3'b000;
    assign rcmask[  6:  4] = 3'b000;
    assign rcmask[ 10:  8] = 3'b000;
    assign rcmask[ 14: 12] = 3'b000;
    assign rcmask[ 18: 16] = 3'b000;
    assign rcmask[ 22: 20] = 3'b000;
    assign rcmask[126: 24] = 103'b0;

    assign state_out = s_perm ^ arkmask ^ rcmask;
endmodule

`default_nettype wire
