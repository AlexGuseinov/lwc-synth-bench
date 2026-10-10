// =============================================================================
// dipper_sbox.v
// 4-bit GIFT S-box, fully combinational, expressed as Boolean equations
// (GIFT bitslice form: 3 AND + 1 OR + 6 XOR + 1 NOT).
//
// This is the area-optimized form from the GIFT paper. Writing the S-box
// as a `case` lookup forces Yosys/ABC to start from a 16:1 MUX tree per
// output bit, which costs ~60 MUX2 per S-box. Writing it as gates lets
// ABC tech-map directly to NAND/NOR/AOI cells in the standard cell library,
// dropping the per-S-box footprint to ~14-18 GE in Nangate45.
//
// Equations (verified against the truth table):
//   b1 = x1 ^ (x0 & x2)
//   a1 = x0 ^ (b1 & x3)
//   c1 = x2 ^ (a1 | b1)
//   d1 = x3 ^ c1
//   b2 = b1 ^ d1
//   d2 = ~d1
//   c2 = c1 ^ (a1 & b2)
//   then swap a1 and d2
//
//   y[0] = d2,  y[1] = b2,  y[2] = c2,  y[3] = a1
//
// Truth table (for verification):
//   in : 0 1 2 3 4 5 6 7 8 9 A B C D E F
//   out: 1 A 4 C 6 F 3 9 2 D B 7 5 0 8 E
// =============================================================================
`default_nettype none

module dipper_sbox (
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

    // After swap of a1 and d2:
    assign y[0] = d2;
    assign y[1] = b2;
    assign y[2] = c2;
    assign y[3] = a1;
endmodule

`default_nettype wire
