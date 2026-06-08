// =============================================================================
// present_key_schedule_128.v
// Combinational key schedule update for PRESENT-128.
//
// Steps:
//   1. K = ROTL(K, 61)                    ( = (K<<61) | (K>>67) )
//   2. K[127:124] = SBOX(K[127:124])
//   3. K[123:120] = SBOX(K[123:120])
//   4. K[66:62]  ^= round_counter[4:0]
//
// Round key = TOP 64 bits of the CURRENT key (use-then-update).
// =============================================================================
`default_nettype none

module present_key_schedule_128 (
    input  wire [127:0] key_in,
    input  wire [  4:0] rc_in,
    output wire [ 63:0] round_key,
    output wire [127:0] key_out
);
    assign round_key = key_in[127:64];

    // ---- Step 1: rotate left 61 (= rotate right 67) ----
    // K_rot = {K_in[66:0], K_in[127:67]}
    wire [127:0] k_rot = {key_in[66:0], key_in[127:67]};

    // ---- Step 2 + 3: two top nibbles through S-box ----
    wire [3:0] sb_top1, sb_top2;
    present_sbox u_ks_sb1 (.x(k_rot[127:124]), .y(sb_top1));
    present_sbox u_ks_sb2 (.x(k_rot[123:120]), .y(sb_top2));

    // ---- Step 4: XOR round counter into K[66:62] ----
    wire [127:0] k_xor;
    assign k_xor[127:124] = sb_top1;
    assign k_xor[123:120] = sb_top2;
    assign k_xor[119: 67] = k_rot[119: 67];
    assign k_xor[ 66: 62] = k_rot[ 66: 62] ^ rc_in;
    assign k_xor[ 61:  0] = k_rot[ 61:  0];

    assign key_out = k_xor;
endmodule

`default_nettype wire
