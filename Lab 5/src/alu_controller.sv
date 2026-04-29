/*
 * alu_controller.sv
 * Second-Level ALU Controller
 *
 * Inputs:
 *   ALUOp [1:0] - from first-level controller
 *     00 : Load/Store  -> ADD
 *     01 : Branch      -> SUB (to check equality)
 *     10 : R-type      -> determined by func3 + func7
 *     11 : I-type arith-> determined by func3 (and func7 for shifts)
 *
 *   func3 [2:0] - instruction bits [14:12]
 *   func7 [6:0] - instruction bits [31:25]
 *
 * Output:
 *   alu_operation [3:0] - to ALU
 */
`include "opcode.vh"

module alu_controller
(
    input  logic [1:0] ALUOp,
    input  logic [2:0] func3,
    input  logic [6:0] func7,
    output logic [3:0] alu_operation
);

    // ALU operation encoding (matches alu.sv)
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
    localparam ALU_PASS = 4'b1010;

    always_comb begin
        case (ALUOp)
            2'b00: begin
                // Load / Store: always ADD for address calculation
                alu_operation = ALU_ADD;
            end

            2'b01: begin
                // Branch: SUB to compare (zero flag used)
                alu_operation = ALU_SUB;
            end

            2'b10: begin
                // R-type: use func3 + func7[5] to determine operation
                case (func3)
                    `FNC_ADD_SUB : alu_operation = (func7[5]) ? ALU_SUB : ALU_ADD;
                    `FNC_SLL     : alu_operation = ALU_SLL;
                    `FNC_SLT     : alu_operation = ALU_SLT;
                    `FNC_SLTU    : alu_operation = ALU_SLTU;
                    `FNC_XOR     : alu_operation = ALU_XOR;
                    `FNC_SRL_SRA : alu_operation = (func7[5]) ? ALU_SRA : ALU_SRL;
                    `FNC_OR      : alu_operation = ALU_OR;
                    `FNC_AND     : alu_operation = ALU_AND;
                    default      : alu_operation = ALU_ADD;
                endcase
            end

            2'b11: begin
                // I-type arithmetic: use func3 (func7[5] for SRAI vs SRLI)
                case (func3)
                    `FNC_ADD_SUB : alu_operation = ALU_ADD;     // ADDI
                    `FNC_SLL     : alu_operation = ALU_SLL;     // SLLI
                    `FNC_SLT     : alu_operation = ALU_SLT;     // SLTI
                    `FNC_SLTU    : alu_operation = ALU_SLTU;    // SLTIU
                    `FNC_XOR     : alu_operation = ALU_XOR;     // XORI
                    `FNC_SRL_SRA : alu_operation = (func7[5]) ? ALU_SRA : ALU_SRL; // SRLI/SRAI
                    `FNC_OR      : alu_operation = ALU_OR;      // ORI
                    `FNC_AND     : alu_operation = ALU_AND;     // ANDI
                    default      : alu_operation = ALU_ADD;
                endcase
            end

            default: alu_operation = ALU_ADD;
        endcase
    end

endmodule
