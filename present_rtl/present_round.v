// =============================================================================
// present_round.v
// One PRESENT round, fully combinational. Reused for 31 cycles by the core.
//
// Round function:
//   1. AddRoundKey : state ^= round_key (full 64-bit XOR)
//   2. SubCells    : 16 parallel PRESENT S-boxes
//   3. PermBits    : PRESENT bit permutation (0 GE)
// =============================================================================
`default_nettype none

module present_round (
    input  wire [63:0] state_in,
    input  wire [63:0] round_key,
    output wire [63:0] state_out
);
    wire [63:0] s_ark = state_in ^ round_key;

    wire [63:0] s_sub;
    genvar j;
    generate
        for (j = 0; j < 16; j = j + 1) begin : sbox_layer
            present_sbox u_sbox (
                .x (s_ark[4*j +: 4]),
                .y (s_sub[4*j +: 4])
            );
        end
    endgenerate

    present_perm u_perm (
        .din  (s_sub),
        .dout (state_out)
    );
endmodule

`default_nettype wire
