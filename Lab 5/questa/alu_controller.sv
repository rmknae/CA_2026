/*
 * Module: alu_controller
 * Description: Generates 4-bit ALU control signals based on ALUOp and instruction fields.
 * Supports R-type, I-type, Load/Store, and Branch instructions.
 */

module alu_controller (
    input  logic [1:0] ALUOp,         // From first-level controller
    input  logic [2:0] func3,         // instruction[14:12]
    input  logic [6:0] func7,         // instruction[31:25]
    output logic [3:0] alu_operation  // To ALU
);

    always_comb begin
        alu_operation = 4'b0010; // Default ADD

        case (ALUOp)
            2'b00: alu_operation = 4'b0010; // Load/Store: ADD for address
            2'b01: alu_operation = 4'b0110; // Branch: SUB for comparison
            2'b10: begin // R-type
                case (func3)
                    3'b000: alu_operation = (func7[5]) ? 4'b0110 : 4'b0010; // SUB / ADD
                    3'b001: alu_operation = 4'b0100; // SLL
                    3'b010: alu_operation = 4'b0111; // SLT
                    3'b011: alu_operation = 4'b1001; // SLTU
                    3'b100: alu_operation = 4'b0011; // XOR
                    3'b101: alu_operation = (func7[5]) ? 4'b1000 : 4'b0101; // SRA / SRL
                    3'b110: alu_operation = 4'b0001; // OR
                    3'b111: alu_operation = 4'b0000; // AND
                    default: alu_operation = 4'b0010;
                endcase
            end
            2'b11: begin // I-type
                case (func3)
                    3'b000: alu_operation = 4'b0010; // ADDI
                    3'b001: alu_operation = 4'b0100; // SLLI
                    3'b010: alu_operation = 4'b0111; // SLTI
                    3'b011: alu_operation = 4'b1001; // SLTIU
                    3'b100: alu_operation = 4'b0011; // XORI
                    3'b101: alu_operation = (func7[5]) ? 4'b1000 : 4'b0101; // SRAI / SRLI
                    3'b110: alu_operation = 4'b0001; // ORI
                    3'b111: alu_operation = 4'b0000; // ANDI
                    default: alu_operation = 4'b0010;
                endcase
            end
            default: alu_operation = 4'b0010;
        endcase
    end

endmodule