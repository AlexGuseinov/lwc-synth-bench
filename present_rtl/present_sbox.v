// =============================================================================
// present_sbox.v
// PRESENT 4-bit S-box, fully combinational.
//
// Truth table:
//   in : 0 1 2 3 4 5 6 7 8 9 A B C D E F
//   out: C 5 6 B 9 0 A D 3 E F 8 4 7 1 2
//
// Implementation note:
//   We use a `case` statement here because this is the canonical form in
//   the PRESENT literature (Bogdanov et al., CHES 2007 and all subsequent
//   hardware reports). Yosys + ABC tech-mapping converts this directly to
//   standard cells.
//
//   This differs from our GIFT and Dipper implementations, which use
//   bitslice Boolean equations. The reason is that each cipher's S-box has
//   a different best-known compact form: GIFT/Dipper share the GIFT bitslice
//   (3 AND + 1 OR + 6 XOR + 1 NOT, ~14 GE), while PRESENT's S-box has
//   higher algebraic degree and is most efficiently mapped from its truth
//   table directly by ABC. Using each cipher's literature-standard form
//   ensures the comparison reflects algorithmic differences, not coding-
//   convention differences.
// =============================================================================
`default_nettype none

module present_sbox (
    input  wire [3:0] x,
    output reg  [3:0] y
);
    always @* begin
        case (x)
            4'h0: y = 4'hC;
            4'h1: y = 4'h5;
            4'h2: y = 4'h6;
            4'h3: y = 4'hB;
            4'h4: y = 4'h9;
            4'h5: y = 4'h0;
            4'h6: y = 4'hA;
            4'h7: y = 4'hD;
            4'h8: y = 4'h3;
            4'h9: y = 4'hE;
            4'hA: y = 4'hF;
            4'hB: y = 4'h8;
            4'hC: y = 4'h4;
            4'hD: y = 4'h7;
            4'hE: y = 4'h1;
            4'hF: y = 4'h2;
            default: y = 4'h0;
        endcase
    end
endmodule

`default_nettype wire
