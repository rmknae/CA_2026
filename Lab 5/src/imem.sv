/*
 * imem.sv
 * Instruction Memory for RISC-V Single-Cycle Processor
 * - Word-addressed (each entry is 32 bits)
 * - Asynchronous read
 * - PC is byte-addressed; we shift right by 2 to get word index
 * - Base address: 0x1000_0000
 */

module imem
#(
    parameter AWIDTH = 14,              // 14-bit word address -> 16K words
    parameter DEPTH  = (1 << AWIDTH)
)
(
    input  logic [31:0] pc,             // Byte-addressed PC
    output logic [31:0] instruction     // 32-bit instruction output
);

    reg [31:0] memory [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'b0;
    end

    // PC is byte-addressed; instruction memory is word-addressed
    // Testbench uses IMEM_PATH.memory[INST_ADDR] where INST_ADDR is a word index
    // PC = 0x1000_0000 corresponds to word index 0
    // Word index = (PC - 0x1000_0000) >> 2
   wire [AWIDTH-1:0] word_addr = pc >> 2;

    assign instruction = memory[word_addr];

endmodule
