// =============================================================================
// dipper_core_96.v
// Round-based iterative implementation of Dipper-64/96.
//
// Architecture (unchanged):
//   - One combinational round datapath (dipper_round) reused for 28 cycles.
//   - One combinational key-schedule update (dipper_key_schedule_96).
//   - 16 parallel S-boxes; 2 parallel 16-bit modular adders.
//
// Control simplification (vs. earlier 3-state FSM):
//   The previous version used IDLE / RUN / DONE states inside a `case`. This
//   inferred a 2-3 level MUX tree per state/key bit (~200 extra MUX2 cells).
//   We collapse to a single `busy` bit and use a flat if-else-if cascade so
//   each register receives exactly one 2:1 load mux:
//     state_r <= load ? plaintext     : state_next_w
//     key_r   <= load ? key           : key_next_w
//     lfsr_r  <= load ? 5'h01         : lfsr_next_w
//     cnt     <= load ? 5'd0          : cnt + 1
//   where load = start & ~busy.
//
// Reset policy:
//   Reset is applied ONLY where correctness requires it:
//     - busy, cnt, lfsr_r, done_r       : RESET REQUIRED
//     - state_r, key_r                  : NO RESET
//                                         (loaded from `plaintext`/`key`
//                                          on `start` before being read).
//   This saves ~160 GE worth of DFFR -> DFFE conversion on the wide regs.
//
// Latency: 1 (load) + 28 (rounds) + 1 (DONE assertion edge) = 30 cycles.
// Throughput: 64 / (30 * T_clk).
// =============================================================================
`default_nettype none

module dipper_core_96 (
    input  wire        clk,
    input  wire        rst,           // synchronous, active-high
    input  wire        start,
    input  wire [63:0] plaintext,
    input  wire [95:0] key,
    output wire [63:0] ciphertext,
    output wire        done
);
    // ---------------------------------------------------------------------
    // Control registers (all reset)
    // ---------------------------------------------------------------------
    reg        busy;
    reg [4:0]  cnt;        // 0..27 during encryption
    reg        done_r;

    // ---------------------------------------------------------------------
    // Datapath registers (state, key: NO reset)
    //   lfsr_r is reset because the very first round needs LFSR=0x01
    //   deterministically and lfsr feeds into combinational logic from
    //   reset onward.
    // ---------------------------------------------------------------------
    reg [63:0] state_r;
    reg [95:0] key_r;
    reg [4:0]  lfsr_r;     // RESET REQUIRED

    // ---------------------------------------------------------------------
    // Combinational round and key-schedule
    // ---------------------------------------------------------------------
    wire [63:0] round_key_w;
    wire [95:0] key_next_w;
    wire [63:0] state_next_w;

    dipper_key_schedule_96 u_ks (
        .key_in    (key_r),
        .rc_in     (lfsr_r),
        .round_key (round_key_w),
        .key_out   (key_next_w)
    );

    dipper_round u_round (
        .state_in  (state_r),
        .round_key (round_key_w),
        .state_out (state_next_w)
    );

    // 5-bit LFSR step (x^5 + x^2 + 1):
    //   bit_new = lfsr[4] ^ lfsr[1]
    //   lfsr_next = {lfsr[3:0], bit_new}
    wire [4:0] lfsr_next_w = {lfsr_r[3:0], lfsr_r[4] ^ lfsr_r[1]};

    // ---------------------------------------------------------------------
    // Single load condition. `busy` and `load` are mutually exclusive:
    // if busy=1 we cannot also be loading. The synthesizer will fold these
    // into a single 2:1 mux + clock-enable per register bit.
    // ---------------------------------------------------------------------
    wire load = start & ~busy;
    wire last = (cnt == 5'd27);

    // ---------------------------------------------------------------------
    // Sequential update
    // ---------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            busy   <= 1'b0;
            cnt    <= 5'd0;
            lfsr_r <= 5'h01;
            done_r <= 1'b0;
        end else if (load) begin
            // Load plaintext, key, fresh LFSR, and start counting.
            state_r <= plaintext;
            key_r   <= key;
            lfsr_r  <= 5'h01;
            cnt     <= 5'd0;
            busy    <= 1'b1;
            done_r  <= 1'b0;
        end else if (busy) begin
            // Apply one round.
            state_r <= state_next_w;
            key_r   <= key_next_w;
            lfsr_r  <= lfsr_next_w;
            cnt     <= cnt + 5'd1;
            if (last) begin
                busy   <= 1'b0;
                done_r <= 1'b1;
            end
        end
        // else: hold (no assignments -> DFFE with EN=0)
    end

    assign ciphertext = state_r;
    assign done       = done_r;
endmodule

`default_nettype wire
