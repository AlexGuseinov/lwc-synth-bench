// =============================================================================
// gift64_core.v
// Round-based iterative implementation of GIFT-64 (128-bit key, 28 rounds).
//
// Architecture mirrors the Dipper v3 pattern for fair comparison:
//   - One combinational round datapath (gift64_round) reused for 28 cycles.
//   - 16 parallel S-boxes; combinational PermBits (zero gates).
//   - Single 1-bit `busy` FSM; the 6-bit RC LFSR also serves as round counter.
//   - Last-round detection by RC value: 28th value is 0x0B.
//
// Reset policy:
//   - busy, rc_r, done_r : RESET REQUIRED
//   - state_r, key_r     : NO RESET (loaded from plaintext / key on `start`)
//
// Latency: 1 (load) + 28 (rounds) + 1 (DONE assertion) = 30 cycles.
// Throughput: 64 / (30 * T_clk).
// =============================================================================
`default_nettype none

module gift64_core (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [ 63:0] plaintext,
    input  wire [127:0] key,
    output wire [ 63:0] ciphertext,
    output wire         done
);
    // ---- Control registers (with reset) ----
    reg          busy;
    reg [  5:0]  rc_r;
    reg          done_r;

    // ---- Datapath registers (no reset) ----
    reg [ 63:0]  state_r;
    reg [127:0]  key_r;

    // ---- Combinational round, key schedule, and RC update ----
    wire [127:0] key_next_w;
    wire [ 63:0] state_next_w;

    // RC LFSR step: (b5,b4,b3,b2,b1,b0) <- (b4,b3,b2,b1,b0, b5^b4^1)
    wire [5:0]   rc_next_w = {rc_r[4:0], rc_r[5] ^ rc_r[4] ^ 1'b1};

    // Round key for GIFT-64: U = k1, V = k0  -> rkey[31:16] = k1, rkey[15:0] = k0
    wire [31:0]  rkey_w = key_r[31:0];   // {k1, k0} = key_r[31:16] || key_r[15:0]

    gift_key_schedule u_ks (
        .key_in  (key_r),
        .key_out (key_next_w)
    );

    gift64_round u_round (
        .state_in  (state_r),
        .rkey      (rkey_w),
        .rc        (rc_next_w),     // use NEXT RC value (matches Python: rc_step then round)
        .state_out (state_next_w)
    );

    // ---- Control signals ----
    wire load = start & ~busy;
    // After 28 RC updates the value is 0x0B; we detect "this is last round"
    // by the round about to be applied (rc_next_w == 0x0B).
    wire last = (rc_next_w == 6'h0B);

    // ---- Control block (reset path lives here) ----
    always @(posedge clk) begin
        if (rst) begin
            busy   <= 1'b0;
            rc_r   <= 6'h00;
            done_r <= 1'b0;
        end else if (load) begin
            busy   <= 1'b1;
            rc_r   <= 6'h00;
            done_r <= 1'b0;
        end else if (busy) begin
            rc_r <= rc_next_w;
            if (last) begin
                busy   <= 1'b0;
                done_r <= 1'b1;
            end
        end
    end

    // ---- Datapath block (no reset) ----
    always @(posedge clk) begin
        if (load) begin
            state_r <= plaintext;
            key_r   <= key;
        end else if (busy) begin
            state_r <= state_next_w;
            key_r   <= key_next_w;
        end
    end

    assign ciphertext = state_r;
    assign done       = done_r;
endmodule

`default_nettype wire
