// =============================================================================
// present_key_schedule_80.v
// Combinational key schedule update for PRESENT-80.
//
// Steps (from the PRESENT spec):
//   1. K = ROTL(K, 61)                    (i.e. K = (K<<61) | (K>>19))
//   2. K[79:76] = SBOX(K[79:76])
//   3. K[19:15] ^= round_counter[4:0]
//
// The round key is the TOP 64 bits of the CURRENT key (use-then-update).
// =============================================================================
`default_nettype none

module present_key_schedule_80 (
    input  wire [79:0] key_in,
    input  wire [ 4:0] rc_in,        // round counter (1..32)
    output wire [63:0] round_key,
    output wire [79:0] key_out
);
    // Round key extraction (use-before-update)
    assign round_key = key_in[79:16];

    // ---- Step 1: rotate left 61 (= rotate right 19) ----
    // K_rot = {K_in[18:0], K_in[79:19]}
    wire [79:0] k_rot = {key_in[18:0], key_in[79:19]};

    // ---- Step 2: top nibble through S-box ----
    wire [3:0] sb_top;
    present_sbox u_ks_sb (.x(k_rot[79:76]), .y(sb_top));

    // ---- Step 3: XOR round counter into K[19:15] ----
    wire [79:0] k_xor;
    assign k_xor[79:76] = sb_top;
    assign k_xor[75:20] = k_rot[75:20];
    assign k_xor[19:15] = k_rot[19:15] ^ rc_in;
    assign k_xor[14: 0] = k_rot[14: 0];

    assign key_out = k_xor;
endmodule

`default_nettype wire
