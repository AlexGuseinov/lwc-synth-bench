// =============================================================================
// dipper_core_128.v
// Round-based iterative implementation of Dipper-64/128.
// Same FSM and register policy as dipper_core_96, but key register is
// 128 bits and uses dipper_key_schedule_128 (3 distributed S-boxes).
// =============================================================================
`default_nettype none

module dipper_core_128 (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [ 63:0] plaintext,
    input  wire [127:0] key,
    output wire [ 63:0] ciphertext,
    output wire         done
);
    reg          busy;
    reg [  4:0]  cnt;
    reg          done_r;

    reg [ 63:0]  state_r;
    reg [127:0]  key_r;
    reg [  4:0]  lfsr_r;

    wire [ 63:0] round_key_w;
    wire [127:0] key_next_w;
    wire [ 63:0] state_next_w;

    dipper_key_schedule_128 u_ks (
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

    wire [4:0] lfsr_next_w = {lfsr_r[3:0], lfsr_r[4] ^ lfsr_r[1]};

    wire load = start & ~busy;
    wire last = (cnt == 5'd27);

    always @(posedge clk) begin
        if (rst) begin
            busy   <= 1'b0;
            cnt    <= 5'd0;
            lfsr_r <= 5'h01;
            done_r <= 1'b0;
        end else if (load) begin
            state_r <= plaintext;
            key_r   <= key;
            lfsr_r  <= 5'h01;
            cnt     <= 5'd0;
            busy    <= 1'b1;
            done_r  <= 1'b0;
        end else if (busy) begin
            state_r <= state_next_w;
            key_r   <= key_next_w;
            lfsr_r  <= lfsr_next_w;
            cnt     <= cnt + 5'd1;
            if (last) begin
                busy   <= 1'b0;
                done_r <= 1'b1;
            end
        end
    end

    assign ciphertext = state_r;
    assign done       = done_r;
endmodule

`default_nettype wire
