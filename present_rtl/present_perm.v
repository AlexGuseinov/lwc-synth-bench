// =============================================================================
// present_perm.v
// PRESENT bit permutation. Pure wire routing, 0 GE.
//
// Specification: P(i) = (16*i) mod 63 for i in 0..62; P(63) = 63
//                dout[P(i)] = din[i]
// Generated automatically from the formula and verified against the Python
// reference (present_reference.py).
// =============================================================================
`default_nettype none

module present_perm (
    input  wire [63:0] din,
    output wire [63:0] dout
);
    assign dout[ 0] = din[ 0];
    assign dout[ 1] = din[ 4];
    assign dout[ 2] = din[ 8];
    assign dout[ 3] = din[12];
    assign dout[ 4] = din[16];
    assign dout[ 5] = din[20];
    assign dout[ 6] = din[24];
    assign dout[ 7] = din[28];
    assign dout[ 8] = din[32];
    assign dout[ 9] = din[36];
    assign dout[10] = din[40];
    assign dout[11] = din[44];
    assign dout[12] = din[48];
    assign dout[13] = din[52];
    assign dout[14] = din[56];
    assign dout[15] = din[60];
    assign dout[16] = din[ 1];
    assign dout[17] = din[ 5];
    assign dout[18] = din[ 9];
    assign dout[19] = din[13];
    assign dout[20] = din[17];
    assign dout[21] = din[21];
    assign dout[22] = din[25];
    assign dout[23] = din[29];
    assign dout[24] = din[33];
    assign dout[25] = din[37];
    assign dout[26] = din[41];
    assign dout[27] = din[45];
    assign dout[28] = din[49];
    assign dout[29] = din[53];
    assign dout[30] = din[57];
    assign dout[31] = din[61];
    assign dout[32] = din[ 2];
    assign dout[33] = din[ 6];
    assign dout[34] = din[10];
    assign dout[35] = din[14];
    assign dout[36] = din[18];
    assign dout[37] = din[22];
    assign dout[38] = din[26];
    assign dout[39] = din[30];
    assign dout[40] = din[34];
    assign dout[41] = din[38];
    assign dout[42] = din[42];
    assign dout[43] = din[46];
    assign dout[44] = din[50];
    assign dout[45] = din[54];
    assign dout[46] = din[58];
    assign dout[47] = din[62];
    assign dout[48] = din[ 3];
    assign dout[49] = din[ 7];
    assign dout[50] = din[11];
    assign dout[51] = din[15];
    assign dout[52] = din[19];
    assign dout[53] = din[23];
    assign dout[54] = din[27];
    assign dout[55] = din[31];
    assign dout[56] = din[35];
    assign dout[57] = din[39];
    assign dout[58] = din[43];
    assign dout[59] = din[47];
    assign dout[60] = din[51];
    assign dout[61] = din[55];
    assign dout[62] = din[59];
    assign dout[63] = din[63];
endmodule

`default_nettype wire
