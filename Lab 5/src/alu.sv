/*
 * alu.sv
 * Arithmetic Logic Unit for RISC-V Single-Cycle Processor
 *
 * alu_operation encoding (4-bit):
 *   0000 : AND
 *   0001 : OR
 *   0010 : ADD
 *   0011 : XOR
 *   0100 : SLL  (shift left logical)
 *   0101 : SRL  (shift right logical)
 *   0110 : SUB
 *   0111 : SRA  (shift right arithmetic)
 *   1000 : SLT  (set less than, signed)
 *   1001 : SLTU (set less than, unsigned)
 *   1010 : LUI_PASS (pass operand2 directly, used for LUI/AUIPC)
 *
 * zero flag: asserted when result == 0 (used for branch comparisons)
 */
`include "opcode.vh"

module alu
(
    input  logic [31:0] operand1,
    input  logic [31:0] operand2,
    input  logic [3:0]  alu_operation,
    output logic [31:0] result,
    output logic        zero
);

    // ALU operation encoding
    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_XOR  = 4'b0011;
    localparam ALU_SLL  = 4'b0100;
    localparam ALU_SRL  = 4'b0101;
    localparam ALU_SUB  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;
    localparam ALU_PASS = 4'b1010;  // Pass operand2 (for LUI)

    always_comb begin

        case (alu_operation)
            ALU_AND  : result = operand1 & operand2;
            ALU_OR   : result = operand1 | operand2;
            ALU_ADD  : result = operand1 + operand2;
            ALU_XOR  : result = operand1 ^ operand2;
            ALU_SLL  : result = operand1 << operand2[4:0];
            ALU_SRL  : result = operand1 >> operand2[4:0];
            ALU_SUB  : result = operand1 - operand2;
            ALU_SRA  : result = $signed(operand1) >>> operand2[4:0];
            ALU_SLT  : result = ($signed(operand1) < $signed(operand2)) ? 32'd1 : 32'd0;
            ALU_SLTU : result = (operand1 < operand2) ? 32'd1 : 32'd0;
            ALU_PASS : result = operand2;
            default  : result = 32'b0;
        endcase

        // Zero flag
        zero = (result == 32'b0);

    end

endmodule