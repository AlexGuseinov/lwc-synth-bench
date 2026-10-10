// =============================================================================
// dipper_round.v
// One Dipper round, fully combinational. Re-used for 28 cycles by the core.
//
// Round function order (locked, do NOT change):
//   1. AddRoundKey   : state ^= round_key                (full 64-bit XOR)
//   2. SubCells      : 16 parallel GIFT S-boxes
//   3. Word Rotations: A1=ROTL16(A,1), B1=ROTL16(B,4),
//                      C1=ROTL16(C,7), D1=ROTL16(D,11)
//   4. ARX           : A2 = (A1+B1) mod 2^16,
//                      C2 = (C1+D1) mod 2^16,
//                      B2 = B1, D2 = D1                  (half-state ARX)
//   5. Bit Permutation: GIFT-64 BOGI permutation
//
// State word layout: A=[63:48], B=[47:32], C=[31:16], D=[15:0].
// =============================================================================
`default_nettype none

module dipper_round (
    input  wire [63:0] state_in,
    input  wire [63:0] round_key,
    output wire [63:0] state_out
);
    // ---- Step 1: AddRoundKey ----
    wire [63:0] s_ark = state_in ^ round_key;

    // ---- Step 2: SubCells (16 parallel GIFT S-boxes) ----
    wire [63:0] s_sub;
    genvar j;
    generate
        for (j = 0; j < 16; j = j + 1) begin : sbox_layer
            dipper_sbox u_sbox (
                .x (s_ark[4*j +: 4]),
                .y (s_sub[4*j +: 4])
            );
        end
    endgenerate

    // ---- Step 3: Word Rotations (fixed wiring, 0 GE) ----
    wire [15:0] A  = s_sub[63:48];
    wire [15:0] B  = s_sub[47:32];
    wire [15:0] C  = s_sub[31:16];
    wire [15:0] D  = s_sub[15: 0];

    // ROTL16(x, n) = {x[15-n:0], x[15:16-n]}
    wire [15:0] A1 = {A[14:0], A[15]};                 // ROTL16(A, 1)
    wire [15:0] B1 = {B[11:0], B[15:12]};              // ROTL16(B, 4)
    wire [15:0] C1 = {C[ 8:0], C[15: 9]};              // ROTL16(C, 7)
    wire [15:0] D1 = {D[ 4:0], D[15: 5]};              // ROTL16(D, 11)

    // ---- Step 4: ARX (2 parallel 16-bit modular adders) ----
    // Plain '+' lets the synthesis tool pick the smallest adder mapping.
    wire [15:0] A2 = A1 + B1;
    wire [15:0] C2 = C1 + D1;
    // B2 = B1, D2 = D1 (no register; pass-through wires)

    wire [63:0] s_arx = {A2, B1, C2, D1};

    // ---- Step 5: Bit Permutation (pure wires, 0 GE) ----
    dipper_perm u_perm (
        .din  (s_arx),
        .dout (state_out)
    );
endmodule

`default_nettype wire
