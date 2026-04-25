/*
 * Module: first_level_controller
 * Updated for Experiment 5: Added Jump, LUI, and Branch support.
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
    output logic       Branch,
    output logic       Jump,    // High for JAL
    output logic       LUISel   // High for LUI
);

    always_comb begin
        // Default values to prevent latches
        ALUOp    = 2'b00;
        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;
        LUISel   = 1'b0;

        case (opcode)
            `OPC_ARI_RTYPE: begin ALUOp = 2'b10; RegWrite = 1'b1; end
            `OPC_ARI_ITYPE: begin ALUOp = 2'b11; RegWrite = 1'b1; ALUSrc = 1'b1; end
            `OPC_LOAD:      begin ALUOp = 2'b00; RegWrite = 1'b1; ALUSrc = 1'b1; MemRead = 1'b1; MemtoReg = 1'b1; end
            `OPC_STORE:     begin ALUOp = 2'b00; ALUSrc = 1'b1; MemWrite = 1'b1; end
            
            // B-type (beq, bne)
            `OPC_BRANCH:    begin ALUOp = 2'b01; Branch = 1'b1; end 
            
            // J-type (jal)
            `OPC_JAL:       begin Jump = 1'b1; RegWrite = 1'b1; end 
            
            // U-type (lui)
            `OPC_LUI:       begin RegWrite = 1'b1; LUISel = 1'b1; end 

            default: ;
        endcase
    end
endmodule