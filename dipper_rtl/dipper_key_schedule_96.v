// =============================================================================
// dipper_key_schedule_96.v
// Combinational key schedule update for Dipper-64/96.
//
// Key layout (96 bits): K = k5 || k4 || k3 || k2 || k1 || k0  (each 16 bits)
//   k5 = K[95:80], k4 = K[79:64], k3 = K[63:48],
//   k2 = K[47:32], k1 = K[31:16], k0 = K[15: 0]
//
// Steps:
//   1. Rotation + word permutation:
//        temp_k1 = ROTR16(k1, 2)
//        temp_k0 = ROTR16(k0, 12)
//        (k5,k4,k3,k2,k1,k0) <- (k3, k2, temp_k1, temp_k0, k5, k4)
//   2. Distributed S-boxes (4) at the canonical bit positions from the spec:
//        K[95:92] <- SBOX(K[95:92])   // top nibble of new k5
//        K[71:68] <- SBOX(K[71:68])   // = new_k4[7:4]   (NOT top nibble)
//        K[47:44] <- SBOX(K[47:44])   // top nibble of new k2
//        K[23:20] <- SBOX(K[23:20])   // = new_k1[7:4]   (NOT top nibble)
//   3. Round-constant injection:
//        K[52:48] <- K[52:48] ^ rc_in[4:0]
//
// Note on the spec's bit positions:
//   The 96-bit key schedule uses K[71:68] and K[23:20], which in word terms
//   are k4[7:4] and k1[7:4] - i.e. the second nibble from the bottom of k4
//   and k1, NOT the top nibble. This matches the Python reference and the
//   locked test vectors.
// =============================================================================
`default_nettype none

module dipper_key_schedule_96 (
    input  wire [95:0] key_in,
    input  wire [ 4:0] rc_in,
    output wire [63:0] round_key,    // lower 64 bits of key_in (use-then-update)
    output wire [95:0] key_out
);
    // Round key is extracted from the CURRENT key (use-then-step).
    assign round_key = key_in[63:0];

    // ---- Split current key into 16-bit words ----
    wire [15:0] k5 = key_in[95:80];
    wire [15:0] k4 = key_in[79:64];
    wire [15:0] k3 = key_in[63:48];
    wire [15:0] k2 = key_in[47:32];
    wire [15:0] k1 = key_in[31:16];
    wire [15:0] k0 = key_in[15: 0];

    // ---- Step 1: rotations on k1, k0; word permutation ----
    // ROTR16(x, n) = {x[n-1:0], x[15:n]}
    wire [15:0] temp_k1 = {k1[1:0],  k1[15:2]};     // ROTR16(k1, 2)
    wire [15:0] temp_k0 = {k0[11:0], k0[15:12]};    // ROTR16(k0, 12)

    // (new_k5, new_k4, new_k3, new_k2, new_k1, new_k0) <-
    //     (k3,    k2,    temp_k1, temp_k0, k5,   k4)
    wire [15:0] nk5_pre = k3;
    wire [15:0] nk4_pre = k2;
    wire [15:0] nk3_pre = temp_k1;
    wire [15:0] nk2_pre = temp_k0;
    wire [15:0] nk1_pre = k5;
    wire [15:0] nk0_pre = k4;

    // ---- Step 2: S-box at the four locked bit positions ----
    //   K[95:92] = nk5[15:12]   (top nibble of k5)
    //   K[71:68] = nk4[ 7: 4]   (lower-mid nibble of k4)
    //   K[47:44] = nk2[15:12]   (top nibble of k2)
    //   K[23:20] = nk1[ 7: 4]   (lower-mid nibble of k1)
    wire [3:0] sb_k5_top, sb_k4_lo,  sb_k2_top, sb_k1_lo;

    dipper_sbox u_ks_sb_k5 (.x(nk5_pre[15:12]), .y(sb_k5_top));
    dipper_sbox u_ks_sb_k4 (.x(nk4_pre[ 7: 4]), .y(sb_k4_lo ));
    dipper_sbox u_ks_sb_k2 (.x(nk2_pre[15:12]), .y(sb_k2_top));
    dipper_sbox u_ks_sb_k1 (.x(nk1_pre[ 7: 4]), .y(sb_k1_lo ));

    wire [15:0] nk5 = {sb_k5_top,                nk5_pre[11:0]};
    wire [15:0] nk4 = {nk4_pre[15:8], sb_k4_lo,  nk4_pre[ 3:0]};
    wire [15:0] nk2 = {sb_k2_top,                nk2_pre[11:0]};
    wire [15:0] nk1 = {nk1_pre[15:8], sb_k1_lo,  nk1_pre[ 3:0]};

    // ---- Step 3: Round-constant injection at K[52:48] ----
    // K[52:48] is bits [4:0] of new k3 (since k3 = K[63:48]).
    wire [15:0] nk3 = {nk3_pre[15:5], nk3_pre[4:0] ^ rc_in};

    // k0 is untouched after step 1
    wire [15:0] nk0 = nk0_pre;

    assign key_out = {nk5, nk4, nk3, nk2, nk1, nk0};
endmodule

`default_nettype wire
