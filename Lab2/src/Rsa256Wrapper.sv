module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_QUERY_RX = 3'b000;
localparam S_READ = 3'b001;
localparam S_WAIT_CALCULATE = 3'b100;
localparam S_QUERY_TX = 3'b010;
localparam S_WRITE = 3'b011;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [  2:0] state_r, state_w;
logic [  6:0] bytes_counter_r, bytes_counter_w;
logic [  4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;


// --------------- wires declaration --------------------
wire rrdy, trdy;
assign rrdy = (avm_waitrequest)? 0: avm_readdata[7];
assign trdy = (avm_waitrequest)? 0: avm_readdata[6];

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = {8'd0, 8'hee};
// assign avm_writedata = dec_r[247-:8];
// ------------------------------------------------------

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask
task Waiting;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = STATUS_BASE;
    end
endtask

always_comb begin
    state_w = state_r;
    StartRead(STATUS_BASE);
    n_w = n_r;
    d_w = d_r;
    enc_w = enc_r;
    case (state_r)
        S_QUERY_RX:
            if (~avm_waitrequest && rrdy) begin
                state_w = S_READ;
                StartRead(RX_BASE);
            end else begin
                state_w = S_QUERY_RX;
                Waiting();
            end
        S_READ:begin
            if(!avm_waitrequest && bytes_counter_r >= 7'd95) begin
                state_w = S_WAIT_CALCULATE;
                n_w = {n_r[247:0], avm_readdata[7:0]};
                d_w = {d_r[247:0], n_r[255:248]};
                enc_w = {enc_r[247:0], d_r[255:248]};
                Waiting();
            end else if (!avm_waitrequest && bytes_counter_r < 7'd95) begin
                state_w = S_QUERY_RX;
                n_w = {n_r[247:0], avm_readdata[7:0]};
                d_w = {d_r[247:0], n_r[255:248]};
                enc_w = {enc_r[247:0], d_r[255:248]};                Waiting();
            end else begin
                state_w = state_r;
                n_w = n_r;
                StartRead(RX_BASE);
            end
        end
        S_WAIT_CALCULATE:
            state_w = S_QUERY_TX;
        S_QUERY_TX: begin
            if (~avm_waitrequest && trdy) begin
                state_w = S_WRITE;
                StartWrite(TX_BASE);
            end else begin
                state_w = S_QUERY_TX;
                StartRead(STATUS_BASE);
            end
        end
        S_WRITE: begin
            // if (~avm_waitrequest && bytes_counter_r == 7'h1f) begin
            //     state_w = S_QUERY_RX;
            //     StartWrite(STATUS_BASE);
            // end else begin
                state_w = state_r;
                StartWrite(TX_BASE);
            // end
        end
    endcase
end

// 4-bits counter for reading the key
always @(*) begin
    if(state_r == S_READ && ~avm_waitrequest)
        bytes_counter_w = bytes_counter_r + 1;
    else if (state_r == S_WAIT_CALCULATE)
        bytes_counter_w = 0;
    else if (state_r == S_WRITE && ~avm_waitrequest)
        bytes_counter_w = bytes_counter_r + 1;
    else if (state_r == S_WRITE && bytes_counter_r == 7'h1f)
        bytes_counter_w = 0;
    else
        bytes_counter_w = bytes_counter_r;
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_QUERY_RX;
        rsa_start_r <= 0;
        bytes_counter_r <= 0;
    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
    end
end

endmodule
