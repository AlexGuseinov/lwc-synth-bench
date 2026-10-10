// =============================================================================
// dipper_key_schedule_128.v
// Combinational key schedule update for Dipper-64/128.
//
// Key layout (128 bits): K = k7||k6||k5||k4||k3||k2||k1||k0   (each 16 bits)
//   k7 = K[127:112], k6 = K[111:96],  k5 = K[95:80],  k4 = K[79:64],
//   k3 = K[63:48],   k2 = K[47:32],   k1 = K[31:16],  k0 = K[15: 0]
//
// Steps:
//   1. Rotation + word permutation:
//        temp_k1 = ROTR16(k1, 2)
//        temp_k0 = ROTR16(k0, 12)
//        (k7,k6,k5,k4,k3,k2,k1,k0) <-
//          (k3, k2, k7, k6, k5, k4, temp_k1, temp_k0)
//   2. Distributed S-boxes (3):
//        K[127:124] <- SBOX(K[127:124])   (top nibble of new k7)
//        K[ 63: 60] <- SBOX(K[ 63: 60])   (top nibble of new k3)
//        K[ 31: 28] <- SBOX(K[ 31: 28])   (top nibble of new k1)
//   3. Round-constant injection:
//        K[68:64] <- K[68:64] ^ rc_in[4:0]
// =============================================================================
`default_nettype none

module dipper_key_schedule_128 (
    input  wire [127:0] key_in,
    input  wire [  4:0] rc_in,
    output wire [ 63:0] round_key,
    output wire [127:0] key_out
);
    // Use-then-step round key extraction.
    assign round_key = key_in[63:0];

    // ---- Split into 16-bit words ----
    wire [15:0] k7 = key_in[127:112];
    wire [15:0] k6 = key_in[111: 96];
    wire [15:0] k5 = key_in[ 95: 80];
    wire [15:0] k4 = key_in[ 79: 64];
    wire [15:0] k3 = key_in[ 63: 48];
    wire [15:0] k2 = key_in[ 47: 32];
    wire [15:0] k1 = key_in[ 31: 16];
    wire [15:0] k0 = key_in[ 15:  0];

    // ---- Step 1: rotations + word permutation ----
    wire [15:0] temp_k1 = {k1[1:0],  k1[15:2]};      // ROTR16(k1, 2)
    wire [15:0] temp_k0 = {k0[11:0], k0[15:12]};     // ROTR16(k0, 12)

    // (new_k7..new_k0) <- (k3, k2, k7, k6, k5, k4, temp_k1, temp_k0)
    wire [15:0] nk7_pre = k3;
    wire [15:0] nk6_pre = k2;
    wire [15:0] nk5_pre = k7;
    wire [15:0] nk4_pre = k6;
    wire [15:0] nk3_pre = k5;
    wire [15:0] nk2_pre = k4;
    wire [15:0] nk1_pre = temp_k1;
    wire [15:0] nk0_pre = temp_k0;

    // ---- Step 2: S-box on three top-nibble positions ----
    wire [3:0] sb_out_k7_top, sb_out_k3_top, sb_out_k1_top;

    dipper_sbox u_ks_sb_k7 (.x(nk7_pre[15:12]), .y(sb_out_k7_top));
    dipper_sbox u_ks_sb_k3 (.x(nk3_pre[15:12]), .y(sb_out_k3_top));
    dipper_sbox u_ks_sb_k1 (.x(nk1_pre[15:12]), .y(sb_out_k1_top));

    wire [15:0] nk7 = {sb_out_k7_top, nk7_pre[11:0]};
    wire [15:0] nk1 = {sb_out_k1_top, nk1_pre[11:0]};

    // K[68:64] = top 5 bits of new k4 (since k4 spans [79:64])
    // After S-box on nk3 top nibble first:
    wire [15:0] nk3 = {sb_out_k3_top, nk3_pre[11:0]};

    // ---- Step 3: RC at K[68:64] ----
    // K[68:64] = nk4[4:0]
    wire [15:0] nk4 = {nk4_pre[15:5], nk4_pre[4:0] ^ rc_in};

    // Untouched words
    wire [15:0] nk6 = nk6_pre;
    wire [15:0] nk5 = nk5_pre;
    wire [15:0] nk2 = nk2_pre;
    wire [15:0] nk0 = nk0_pre;

    assign key_out = {nk7, nk6, nk5, nk4, nk3, nk2, nk1, nk0};
endmodule

`default_nettype wire
