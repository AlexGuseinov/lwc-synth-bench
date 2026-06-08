// =============================================================================
// gift_sbox.v
// 4-bit GIFT S-box, bitslice Boolean form (3 AND + 1 OR + 6 XOR + 1 NOT).
// Tech-maps directly to NAND/NOR/AOI cells via ABC, avoiding the 16:1 MUX
// tree that a `case` lookup would force.
//
// Truth table:
//   in : 0 1 2 3 4 5 6 7 8 9 A B C D E F
//   out: 1 A 4 C 6 F 3 9 2 D B 7 5 0 8 E
// =============================================================================
`default_nettype none

module gift_sbox (
    input  wire [3:0] x,
    output wire [3:0] y
);
    wire a = x[0];
    wire b = x[1];
    wire c = x[2];
    wire d = x[3];

    wire b1 = b ^ (a & c);
    wire a1 = a ^ (b1 & d);
    wire c1 = c ^ (a1 | b1);
    wire d1 = d ^ c1;
    wire b2 = b1 ^ d1;
    wire d2 = ~d1;
    wire c2 = c1 ^ (a1 & b2);

    assign y[0] = d2;
    assign y[1] = b2;
    assign y[2] = c2;
    assign y[3] = a1;
endmodule

`default_nettype wire
