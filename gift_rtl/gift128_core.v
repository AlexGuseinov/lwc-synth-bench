// =============================================================================
// gift128_core.v
// Round-based iterative implementation of GIFT-128 (128-bit key, 40 rounds).
//
// Same control structure as gift64_core, but:
//   - state register is 128 bits
//   - 32 parallel S-boxes per round
//   - round key is 64 bits: U||V = k5||k4 || k1||k0
//   - 40 rounds; last RC value is 0x1A
//
// Latency: 1 (load) + 40 (rounds) + 1 (DONE assertion) = 42 cycles.
// Throughput: 128 / (42 * T_clk).
// =============================================================================
`default_nettype none

module gift128_core (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output wire [127:0] ciphertext,
    output wire         done
);
    // ---- Control registers ----
    reg          busy;
    reg [  5:0]  rc_r;
    reg          done_r;

    // ---- Datapath registers (no reset) ----
    reg [127:0]  state_r;
    reg [127:0]  key_r;

    // ---- Combinational round, key schedule, RC step ----
    wire [127:0] key_next_w;
    wire [127:0] state_next_w;
    wire [  5:0] rc_next_w = {rc_r[4:0], rc_r[5] ^ rc_r[4] ^ 1'b1};

    // Round key for GIFT-128:
    //   U = k5||k4 = key_r[95:64]
    //   V = k1||k0 = key_r[31: 0]
    //   rkey = {U, V}
    wire [63:0] rkey_w = {key_r[95:64], key_r[31:0]};

    gift_key_schedule u_ks (
        .key_in  (key_r),
        .key_out (key_next_w)
    );

    gift128_round u_round (
        .state_in  (state_r),
        .rkey      (rkey_w),
        .rc        (rc_next_w),
        .state_out (state_next_w)
    );

    // ---- Control signals ----
    wire load = start & ~busy;
    // 40th RC value is 0x1A.
    wire last = (rc_next_w == 6'h1A);

    // ---- Control block ----
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

    // ---- Datapath block ----
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
