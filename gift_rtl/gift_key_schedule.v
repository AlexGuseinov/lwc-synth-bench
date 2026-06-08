// =============================================================================
// gift_key_schedule.v
// Combinational key schedule update for GIFT (128-bit key state).
// Same update rule for GIFT-64 and GIFT-128.
//
// Key state: K = k7||k6||k5||k4||k3||k2||k1||k0  (each 16-bit)
//   k7 = K[127:112], k6 = K[111:96], ..., k0 = K[15:0]
//
// Update:
//   New K = ROTR(k1, 2) || ROTR(k0, 12) || k7 || k6 || k5 || k4 || k3 || k2
//
// The round-key extraction is done outside this module:
//   GIFT-64  : RK = U||V = k1 || k0      (32 bits)
//   GIFT-128 : RK = U||V = k5||k4 || k1||k0  (64 bits)
// =============================================================================
`default_nettype none

module gift_key_schedule (
    input  wire [127:0] key_in,
    output wire [127:0] key_out
);
    wire [15:0] k7 = key_in[127:112];
    wire [15:0] k6 = key_in[111: 96];
    wire [15:0] k5 = key_in[ 95: 80];
    wire [15:0] k4 = key_in[ 79: 64];
    wire [15:0] k3 = key_in[ 63: 48];
    wire [15:0] k2 = key_in[ 47: 32];
    wire [15:0] k1 = key_in[ 31: 16];
    wire [15:0] k0 = key_in[ 15:  0];

    // ROTR(x, n) = {x[n-1:0], x[15:n]}
    wire [15:0] k1_r2  = {k1[1:0],  k1[15:2]};       // ROTR(k1, 2)
    wire [15:0] k0_r12 = {k0[11:0], k0[15:12]};      // ROTR(k0, 12)

    assign key_out = {k1_r2, k0_r12, k7, k6, k5, k4, k3, k2};
endmodule

`default_nettype wire
