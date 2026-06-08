// =============================================================================
// present_core_80.v
// Round-based iterative implementation of PRESENT-80.
//
// Algorithm: 31 rounds of (AddRoundKey, SubCells, PermBits) plus a final
// 32nd post-whitening (just AddRoundKey).
//
// Architecture (mirrors Dipper v3 / GIFT for fair comparison):
//   - One combinational round datapath (present_round) for the 31 full rounds.
//   - One combinational key schedule (present_key_schedule_80).
//   - Single 1-bit `busy` FSM; round counter via 5-bit register (rc_r).
//
// Cycle layout:
//   cycle 0 : load (start sampled)
//   cycles 1..31: rounds 1..31 applied to (state, key)
//                 -> at the end of cycle 31 the state holds round-31 output,
//                    and key has been updated to its round-32 value.
//   cycle 32 : final post-whitening: state ^= round_key[round 32]
//   cycle 33 : DONE asserted
//
// Total latency ≈ 33 cycles per block.
// Throughput: 64 / (33 * T_clk).
//
// Reset policy:
//   - busy, rc_r, post_r, done_r : RESET REQUIRED
//   - state_r, key_r             : NO RESET
// =============================================================================
`default_nettype none

module present_core_80 (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [63:0] plaintext,
    input  wire [79:0] key,
    output wire [63:0] ciphertext,
    output wire        done
);
    // ---- Control registers ----
    reg        busy;        // running rounds 1..31
    reg [4:0]  rc_r;        // round counter (1..31)
    reg        post_r;      // post-whitening cycle flag
    reg        done_r;

    // ---- Datapath registers (no reset) ----
    reg [63:0] state_r;
    reg [79:0] key_r;

    // ---- Combinational ----
    wire [63:0] round_key_w;
    wire [79:0] key_next_w;
    wire [63:0] state_next_w;

    // The round counter passed to the key schedule for the *current* round
    // is rc_r (which equals the number of rounds completed so far + 1 when
    // we are about to apply a round). PRESENT's spec uses round counter 1..31.
    // We compute "next" round counter as (rc_r + 1) for the increment path,
    // but the value INJECTED into the schedule must be the round counter of
    // the round we are CURRENTLY applying = rc_r itself.
    present_key_schedule_80 u_ks (
        .key_in    (key_r),
        .rc_in     (rc_r),
        .round_key (round_key_w),
        .key_out   (key_next_w)
    );

    present_round u_round (
        .state_in  (state_r),
        .round_key (round_key_w),
        .state_out (state_next_w)
    );

    // ---- Control signals ----
    wire load        = start & ~busy & ~post_r & ~done_r;
    wire last_round  = (rc_r == 5'd31);

    // ---- Control block ----
    always @(posedge clk) begin
        if (rst) begin
            busy   <= 1'b0;
            rc_r   <= 5'd1;
            post_r <= 1'b0;
            done_r <= 1'b0;
        end else if (load) begin
            busy   <= 1'b1;
            rc_r   <= 5'd1;
            post_r <= 1'b0;
            done_r <= 1'b0;
        end else if (busy) begin
            if (last_round) begin
                // After applying round 31, transition to post-whitening cycle.
                busy   <= 1'b0;
                post_r <= 1'b1;
            end else begin
                rc_r <= rc_r + 5'd1;
            end
        end else if (post_r) begin
            // Final post-whitening cycle: assert done next.
            post_r <= 1'b0;
            done_r <= 1'b1;
        end
    end

    // ---- Datapath block (no reset) ----
    // For rounds 1..31:  state <= round(state, RK), key <= ks(key, rc_r)
    // For post-whitening: state <= state ^ RK[32]
    always @(posedge clk) begin
        if (load) begin
            state_r <= plaintext;
            key_r   <= key;
        end else if (busy) begin
            state_r <= state_next_w;
            key_r   <= key_next_w;
        end else if (post_r) begin
            // Final whitening: round_key_w is the top 64 bits of the
            // already-updated key (i.e. the 32nd round key).
            state_r <= state_r ^ round_key_w;
        end
    end

    assign ciphertext = state_r;
    assign done       = done_r;
endmodule

`default_nettype wire
