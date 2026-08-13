// alu3_pipeline - 3-stage synchronous pipelined ALU (easy concept).
//
// Pipeline stages (one register stage each):
//   STAGE 1  REG   : capture operands a, b, opcode + valid bit
//   STAGE 2  EX    : combinational ALU executes, result captured in reg
//   STAGE 3  WB    : writeback register drives the outputs
//
// Latency: valid_out asserts exactly 3 clock cycles after valid_in.
// Operations (op):
//   000  ADD   result = a + b
//   001  SUB   result = a - b
//   010  AND   result = a & b
//   011  OR    result = a | b
//   100  XOR   result = a ^ b
//   101  SLT   result = (a < b) ? 1 : 0        (signed compare)
//   110  SLL   result = a << b[4:0]
//   111  SRL   result = a >> b[4:0]            (logical)

module alu3_pipeline #(
    parameter int DATA_W = 32
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     valid_in,
    input  logic [DATA_W-1:0]        a,
    input  logic [DATA_W-1:0]        b,
    input  logic [2:0]               op,
    output logic                     valid_out,
    output logic [DATA_W-1:0]        result
);

    // =================================================================
    // STAGE 1 - operand register
    // =================================================================
    logic [DATA_W-1:0] a1;
    logic [DATA_W-1:0] b1;
    logic [2:0]        op1;
    logic              v1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a1  <= '0;
            b1  <= '0;
            op1 <= '0;
            v1  <= 1'b0;
        end else begin
            a1  <= a;
            b1  <= b;
            op1 <= op;
            v1  <= valid_in;
        end
    end

    // =================================================================
    // STAGE 2 - ALU execute (combinational logic in the pipeline)
    // =================================================================
    logic [DATA_W-1:0] alu_out;

    always_comb begin
        unique case (op1)
            3'b000: alu_out = a1 + b1;                         // ADD
            3'b001: alu_out = a1 - b1;                         // SUB
            3'b010: alu_out = a1 & b1;                         // AND
            3'b011: alu_out = a1 | b1;                         // OR
            3'b100: alu_out = a1 ^ b1;                         // XOR
            3'b101: alu_out = {31'b0, ($signed(a1) < $signed(b1))}; // SLT
            3'b110: alu_out = a1 << (b1[4:0]);                 // SLL
            default: alu_out = a1 >> (b1[4:0]);                // SRL
        endcase
    end

    logic [DATA_W-1:0] r2;
    logic              v2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r2 <= '0;
            v2 <= 1'b0;
        end else begin
            r2 <= alu_out;
            v2 <= v1;
        end
    end

    // =================================================================
    // STAGE 3 - writeback register
    // =================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result    <= '0;
            valid_out <= 1'b0;
        end else begin
            result    <= r2;
            valid_out <= v2;
        end
    end

endmodule
