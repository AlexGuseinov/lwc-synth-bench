// =============================================================================
// gift128_perm.v
// GIFT-128 BOGI bit permutation. Pure wire routing, 0 GE.
//
// Specification: dout[P128(i)] = din[i] for i = 0..127
// where P128(i) = 4*floor(i/16) + 32*((3*floor((i mod 16)/4) + (i mod 4)) mod 4)
//                 + (i mod 4)
//
// Generated automatically from the formula and verified against the Python
// reference (gift_reference.py).
// =============================================================================
`default_nettype none

module gift128_perm (
    input  wire [127:0] din,
    output wire [127:0] dout
);
    assign dout[  0] = din[  0];
    assign dout[  1] = din[  5];
    assign dout[  2] = din[ 10];
    assign dout[  3] = din[ 15];
    assign dout[  4] = din[ 16];
    assign dout[  5] = din[ 21];
    assign dout[  6] = din[ 26];
    assign dout[  7] = din[ 31];
    assign dout[  8] = din[ 32];
    assign dout[  9] = din[ 37];
    assign dout[ 10] = din[ 42];
    assign dout[ 11] = din[ 47];
    assign dout[ 12] = din[ 48];
    assign dout[ 13] = din[ 53];
    assign dout[ 14] = din[ 58];
    assign dout[ 15] = din[ 63];
    assign dout[ 16] = din[ 64];
    assign dout[ 17] = din[ 69];
    assign dout[ 18] = din[ 74];
    assign dout[ 19] = din[ 79];
    assign dout[ 20] = din[ 80];
    assign dout[ 21] = din[ 85];
    assign dout[ 22] = din[ 90];
    assign dout[ 23] = din[ 95];
    assign dout[ 24] = din[ 96];
    assign dout[ 25] = din[101];
    assign dout[ 26] = din[106];
    assign dout[ 27] = din[111];
    assign dout[ 28] = din[112];
    assign dout[ 29] = din[117];
    assign dout[ 30] = din[122];
    assign dout[ 31] = din[127];
    assign dout[ 32] = din[ 12];
    assign dout[ 33] = din[  1];
    assign dout[ 34] = din[  6];
    assign dout[ 35] = din[ 11];
    assign dout[ 36] = din[ 28];
    assign dout[ 37] = din[ 17];
    assign dout[ 38] = din[ 22];
    assign dout[ 39] = din[ 27];
    assign dout[ 40] = din[ 44];
    assign dout[ 41] = din[ 33];
    assign dout[ 42] = din[ 38];
    assign dout[ 43] = din[ 43];
    assign dout[ 44] = din[ 60];
    assign dout[ 45] = din[ 49];
    assign dout[ 46] = din[ 54];
    assign dout[ 47] = din[ 59];
    assign dout[ 48] = din[ 76];
    assign dout[ 49] = din[ 65];
    assign dout[ 50] = din[ 70];
    assign dout[ 51] = din[ 75];
    assign dout[ 52] = din[ 92];
    assign dout[ 53] = din[ 81];
    assign dout[ 54] = din[ 86];
    assign dout[ 55] = din[ 91];
    assign dout[ 56] = din[108];
    assign dout[ 57] = din[ 97];
    assign dout[ 58] = din[102];
    assign dout[ 59] = din[107];
    assign dout[ 60] = din[124];
    assign dout[ 61] = din[113];
    assign dout[ 62] = din[118];
    assign dout[ 63] = din[123];
    assign dout[ 64] = din[  8];
    assign dout[ 65] = din[ 13];
    assign dout[ 66] = din[  2];
    assign dout[ 67] = din[  7];
    assign dout[ 68] = din[ 24];
    assign dout[ 69] = din[ 29];
    assign dout[ 70] = din[ 18];
    assign dout[ 71] = din[ 23];
    assign dout[ 72] = din[ 40];
    assign dout[ 73] = din[ 45];
    assign dout[ 74] = din[ 34];
    assign dout[ 75] = din[ 39];
    assign dout[ 76] = din[ 56];
    assign dout[ 77] = din[ 61];
    assign dout[ 78] = din[ 50];
    assign dout[ 79] = din[ 55];
    assign dout[ 80] = din[ 72];
    assign dout[ 81] = din[ 77];
    assign dout[ 82] = din[ 66];
    assign dout[ 83] = din[ 71];
    assign dout[ 84] = din[ 88];
    assign dout[ 85] = din[ 93];
    assign dout[ 86] = din[ 82];
    assign dout[ 87] = din[ 87];
    assign dout[ 88] = din[104];
    assign dout[ 89] = din[109];
    assign dout[ 90] = din[ 98];
    assign dout[ 91] = din[103];
    assign dout[ 92] = din[120];
    assign dout[ 93] = din[125];
    assign dout[ 94] = din[114];
    assign dout[ 95] = din[119];
    assign dout[ 96] = din[  4];
    assign dout[ 97] = din[  9];
    assign dout[ 98] = din[ 14];
    assign dout[ 99] = din[  3];
    assign dout[100] = din[ 20];
    assign dout[101] = din[ 25];
    assign dout[102] = din[ 30];
    assign dout[103] = din[ 19];
    assign dout[104] = din[ 36];
    assign dout[105] = din[ 41];
    assign dout[106] = din[ 46];
    assign dout[107] = din[ 35];
    assign dout[108] = din[ 52];
    assign dout[109] = din[ 57];
    assign dout[110] = din[ 62];
    assign dout[111] = din[ 51];
    assign dout[112] = din[ 68];
    assign dout[113] = din[ 73];
    assign dout[114] = din[ 78];
    assign dout[115] = din[ 67];
    assign dout[116] = din[ 84];
    assign dout[117] = din[ 89];
    assign dout[118] = din[ 94];
    assign dout[119] = din[ 83];
    assign dout[120] = din[100];
    assign dout[121] = din[105];
    assign dout[122] = din[110];
    assign dout[123] = din[ 99];
    assign dout[124] = din[116];
    assign dout[125] = din[121];
    assign dout[126] = din[126];
    assign dout[127] = din[115];
endmodule

`default_nettype wire
