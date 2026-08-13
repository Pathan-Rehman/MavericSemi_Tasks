// Self-checking testbench for the 3-stage pipelined ALU (alu3_pipeline).
// Usage: tclsh scripts/sim.tcl   (iverilog + vvp, writes tb_alu3_pipeline.vcd)
//
// The reference model mirrors the RTL stage by stage (REG -> EX -> WB) and
// compares result / valid_out on every clock edge after reset.

module tb_alu3_pipeline;

    localparam int DATA_W = 32;
    localparam int N_CHECKS = 200;

    logic clk = 0;
    logic rst_n = 0;
    logic valid_in = 0;
    logic [DATA_W-1:0] a;
    logic [DATA_W-1:0] b;
    logic [2:0]        op;
    logic valid_out;
    logic [DATA_W-1:0] result;

    alu3_pipeline #(
        .DATA_W(DATA_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .op(op),
        .valid_out(valid_out),
        .result(result)
    );

    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    //  Reference model: mirrors the RTL's 3 register stages exactly
    // ---------------------------------------------------------------
    logic [DATA_W-1:0] a1_ref;
    logic [DATA_W-1:0] b1_ref;
    logic [2:0]        op1_ref;
    logic              v1_ref;

    logic [DATA_W-1:0] alu_out_ref;
    logic [DATA_W-1:0] r2_ref;
    logic              v2_ref;

    logic [DATA_W-1:0] result_ref;
    logic              valid_out_ref;

    always_comb begin
        case (op1_ref)
            3'b000: alu_out_ref = a1_ref + b1_ref;
            3'b001: alu_out_ref = a1_ref - b1_ref;
            3'b010: alu_out_ref = a1_ref & b1_ref;
            3'b011: alu_out_ref = a1_ref | b1_ref;
            3'b100: alu_out_ref = a1_ref ^ b1_ref;
            3'b101: alu_out_ref = {31'b0, ($signed(a1_ref) < $signed(b1_ref))};
            3'b110: alu_out_ref = a1_ref << (b1_ref[4:0]);
            default: alu_out_ref = a1_ref >> (b1_ref[4:0]);
        endcase
    end

    // STAGE 1
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a1_ref  <= '0;
            b1_ref  <= '0;
            op1_ref <= '0;
            v1_ref  <= 1'b0;
        end else begin
            a1_ref  <= a;
            b1_ref  <= b;
            op1_ref <= op;
            v1_ref  <= valid_in;
        end
    end

    // STAGE 2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r2_ref <= '0;
            v2_ref <= 1'b0;
        end else begin
            r2_ref <= alu_out_ref;
            v2_ref <= v1_ref;
        end
    end

    // STAGE 3
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_ref    <= '0;
            valid_out_ref <= 1'b0;
        end else begin
            result_ref    <= r2_ref;
            valid_out_ref <= v2_ref;
        end
    end

    // ---------------------------------------------------------------
    //  Stimulus + checking
    // ---------------------------------------------------------------
    int errors = 0;
    int nchecks = 0;

    initial begin
        $dumpfile("tb_alu3_pipeline.vcd");
        $dumpvars(0, tb_alu3_pipeline);

        a  = '0;
        b  = '0;
        op = '0;

        // reset
        rst_n = 0;
        valid_in = 0;
        repeat (3) @(posedge clk);

        @(negedge clk);
        rst_n = 1;
        valid_in = 1;

        for (int i = 0; i < N_CHECKS; i++) begin
            @(negedge clk);
            a  = $random;
            b  = $random;
            op = 3'($unsigned($random) % 8);

            @(posedge clk);
            #1;

            if (valid_out !== valid_out_ref) begin
                $display("  [t=%0t] valid_out mismatch: DUT=%0b REF=%0b",
                         $time, valid_out, valid_out_ref);
                errors++;
            end
            if (result !== result_ref) begin
                $display("  [t=%0t] result mismatch: DUT=%0d REF=%0d (op=%0b a=%0d b=%0d)",
                         $time, result, result_ref, op1_ref, a1_ref, b1_ref);
                errors++;
            end
            nchecks++;
        end

        @(negedge clk);
        valid_in = 0;

        if (errors == 0)
            $display("SIM PASS: %0d outputs checked", nchecks);
        else
            $display("SIM FAIL: %0d errors out of %0d outputs checked", errors, nchecks);
        $finish;
    end

endmodule
