/*
 * main_controller.sv
 * First-Level (Main) Controller for RISC-V Single-Cycle Processor
 *
 * Input:
 *   opcode [6:0] - instruction bits [6:0]
 *
 * Outputs:
 *   ALUOp   [1:0] - to ALU controller
 *     10 = R-type, 11 = I-type arith, 00 = Load/Store, 01 = Branch
 *   ALUSrc        - 0: operand2 = rs2, 1: operand2 = immediate
 *   MemtoReg[1:0] - writeback source select
 *     00 = ALU result, 01 = Data memory, 10 = PC+4, 11 = immediate (LUI/AUIPC)
 *   RegWrite      - 1: write to register file
 *   MemRead       - 1: read data memory
 *   MemWrite      - 1: write data memory
 *   Branch        - 1: this is a branch instruction
 *   Jump          - 1: this is JAL
 *   JumpR         - 1: this is JALR
 *   LUI           - 1: pass upper immediate directly
 *   AUIPC         - 1: PC + upper immediate
 */
`include "opcode.vh"

module main_controller
(
    input  logic [6:0] opcode,
    output logic [1:0] ALUOp,
    output logic       ALUSrc,
    output logic [1:0] MemtoReg,
    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       Branch,
    output logic       Jump,
    output logic       JumpR,
    output logic       LUI,
    output logic       AUIPC
);

    always_comb begin
        // Default all signals
        ALUOp    = 2'b00;
        ALUSrc   = 1'b0;
        MemtoReg = 2'b00;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;
        JumpR    = 1'b0;
        LUI      = 1'b0;
        AUIPC    = 1'b0;

        case (opcode)
            `OPC_ARI_RTYPE: begin
                // R-type: add, sub, and, or, xor, sll, srl, sra, slt, sltu
                ALUOp    = 2'b10;   // R-type
                ALUSrc   = 1'b0;    // operand2 = rs2
                MemtoReg = 2'b00;   // writeback = ALU result
                RegWrite = 1'b1;    // write to rd
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
            end

            `OPC_ARI_ITYPE: begin
                // I-type arithmetic: addi, slti, sltiu, xori, ori, andi, slli, srli, srai
                ALUOp    = 2'b11;   // I-type arithmetic
                ALUSrc   = 1'b1;    // operand2 = immediate
                MemtoReg = 2'b00;   // writeback = ALU result
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
            end

            `OPC_LOAD: begin
                // I-type load: lb, lh, lw, lbu, lhu
                ALUOp    = 2'b00;   // ADD for address
                ALUSrc   = 1'b1;    // operand2 = immediate
                MemtoReg = 2'b01;   // writeback = data memory
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemWrite = 1'b0;
                Branch   = 1'b0;
            end

            `OPC_STORE: begin
                // S-type: sb, sh, sw
                ALUOp    = 2'b00;   // ADD for address
                ALUSrc   = 1'b1;    // operand2 = immediate
                MemtoReg = 2'b00;   // don't care (no writeback)
                RegWrite = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b1;
                Branch   = 1'b0;
            end

            `OPC_BRANCH: begin
                // B-type: beq, bne, blt, bge, bltu, bgeu
                ALUOp    = 2'b01;   // SUB for comparison
                ALUSrc   = 1'b0;    // operand2 = rs2
                MemtoReg = 2'b00;   // don't care
                RegWrite = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b1;
            end

            `OPC_JAL: begin
                // J-type: jal - rd = PC+4, PC = PC + imm
                ALUOp    = 2'b00;   // ADD for target (not used directly)
                ALUSrc   = 1'b1;
                MemtoReg = 2'b10;   // writeback = PC+4
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                Jump     = 1'b1;
            end

            `OPC_JALR: begin
                // I-type: jalr - rd = PC+4, PC = (rs1 + imm) & ~1
                ALUOp    = 2'b00;   // ADD for target address
                ALUSrc   = 1'b1;
                MemtoReg = 2'b10;   // writeback = PC+4
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                JumpR    = 1'b1;
            end

            `OPC_LUI: begin
                // U-type: lui - rd = {imm20, 12'b0}
                ALUOp    = 2'b00;
                ALUSrc   = 1'b1;
                MemtoReg = 2'b11;   // writeback = immediate directly
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                LUI      = 1'b1;
            end

            `OPC_AUIPC: begin
                // U-type: auipc - rd = PC + {imm20, 12'b0}
                ALUOp    = 2'b00;   // ADD: PC + imm
                ALUSrc   = 1'b1;
                MemtoReg = 2'b00;   // writeback = ALU result (PC + imm)
                RegWrite = 1'b1;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                AUIPC    = 1'b1;
            end

            default: begin
                ALUOp    = 2'b00;
                ALUSrc   = 1'b0;
                MemtoReg = 2'b00;
                RegWrite = 1'b0;
                MemRead  = 1'b0;
                MemWrite = 1'b0;
                Branch   = 1'b0;
                Jump     = 1'b0;
                JumpR    = 1'b0;
                LUI      = 1'b0;
                AUIPC    = 1'b0;
            end
        endcase
    end

endmodule
