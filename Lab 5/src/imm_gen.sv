/*
 * imm_gen.sv
 * Immediate Generator for RISC-V Single-Cycle Processor
 *
 * Extracts and sign-extends immediates for all instruction formats:
 *   I-type : inst[31:20] sign-extended to 32 bits
 *   S-type : {inst[31:25], inst[11:7]} sign-extended to 32 bits
 *   B-type : {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0} sign-extended
 *   U-type : {inst[31:12], 12'b0} (LUI / AUIPC)
 *   J-type : {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0} sign-extended
 *
 * Opcode is used to determine the instruction format.
 */
`include "opcode.vh"

module imm_gen
(
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    wire [6:0] opcode = instruction[6:0];

    always_comb begin
        case (opcode)
            // I-type: arithmetic, load, jalr
            `OPC_ARI_ITYPE,
            `OPC_LOAD,
            `OPC_JALR    : immediate = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: store
            `OPC_STORE   : immediate = {{20{instruction[31]}},
                                         instruction[31:25],
                                         instruction[11:7]};

            // B-type: branch
            `OPC_BRANCH  : immediate = {{19{instruction[31]}},
                                         instruction[31],
                                         instruction[7],
                                         instruction[30:25],
                                         instruction[11:8],
                                         1'b0};

            // U-type: LUI, AUIPC
            `OPC_LUI,
            `OPC_AUIPC   : immediate = {instruction[31:12], 12'b0};

            // J-type: JAL
            `OPC_JAL     : immediate = {{11{instruction[31]}},
                                         instruction[31],
                                         instruction[19:12],
                                         instruction[20],
                                         instruction[30:21],
                                         1'b0};

            default       : immediate = 32'b0;
        endcase
    end

endmodule
