// =============================================================================
// present_core_128.v
// Round-based iterative implementation of PRESENT-128.
// Same FSM as present_core_80 but with 128-bit key and the 128-bit
// key schedule.
// =============================================================================
`default_nettype none

module present_core_128 (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [ 63:0] plaintext,
    input  wire [127:0] key,
    output wire [ 63:0] ciphertext,
    output wire         done
);
    reg          busy;
    reg [  4:0]  rc_r;
    reg          post_r;
    reg          done_r;

    reg [ 63:0]  state_r;
    reg [127:0]  key_r;

    wire [ 63:0] round_key_w;
    wire [127:0] key_next_w;
    wire [ 63:0] state_next_w;

    present_key_schedule_128 u_ks (
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

    wire load       = start & ~busy & ~post_r & ~done_r;
    wire last_round = (rc_r == 5'd31);

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
                busy   <= 1'b0;
                post_r <= 1'b1;
            end else begin
                rc_r <= rc_r + 5'd1;
            end
        end else if (post_r) begin
            post_r <= 1'b0;
            done_r <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (load) begin
            state_r <= plaintext;
            key_r   <= key;
        end else if (busy) begin
            state_r <= state_next_w;
            key_r   <= key_next_w;
        end else if (post_r) begin
            state_r <= state_r ^ round_key_w;
        end
    end

    assign ciphertext = state_r;
    assign done       = done_r;
endmodule

`default_nettype wire
