/*
 * Module: first_level_controller
 * Description: Main control unit for a single-cycle RISC-V datapath.
 * Decodes opcodes to generate all necessary control signals for Task 4.
 */

`include "opcode.vh"

module first_level_controller (
    input  logic [6:0] opcode,
    output logic [1:0] ALUOp,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       MemtoReg,
    output logic       Branch
);

    always_comb begin
        // Default values to prevent latches and simplify logic
        ALUOp    = 2'b00;
        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;

        case (opcode)
            // R-type Instructions
            `OPC_ARI_RTYPE: begin
                ALUOp    = 2'b10;
                RegWrite = 1'b1;
                ALUSrc   = 1'b0; // Use rs2 register
            end

            // I-type Arithmetic Instructions
            `OPC_ARI_ITYPE: begin
                ALUOp    = 2'b11;
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // Use immediate
            end

            // Load Word (LW)
            `OPC_LOAD: begin
                ALUOp    = 2'b00; // Add for address calculation
                RegWrite = 1'b1;
                ALUSrc   = 1'b1; // Use immediate offset
                MemRead  = 1'b1;
                MemtoReg = 1'b1; // Select Data Memory output
            end

            // Store Word (SW)
            `OPC_STORE: begin
                ALUOp    = 2'b00; // Add for address calculation
                RegWrite = 1'b0;
                ALUSrc   = 1'b1; // Use immediate offset
                MemWrite = 1'b1;
            end

            // Branch Instructions (e.g., BEQ)
            `OPC_BRANCH: begin
                ALUOp    = 2'b01; // Subtract for comparison
                RegWrite = 1'b0;
                ALUSrc   = 1'b0; // Compare two registers
                Branch   = 1'b1;
            end

            default: begin
                ALUOp    = 2'b00;
                RegWrite = 1'b0;
            end
        endcase
    end

endmodule