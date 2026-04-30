/*
 * dmem.sv
 * Data Memory for RISC-V Single-Cycle Processor
 * - Word-addressed: address is used directly as word index
 * - Synchronous write, asynchronous read
 * - The ALU result is the word address (no byte-to-word conversion needed
 * because testbench initializes DMEM as: memory[reg_val + imm] = data)
 */

module dmem
#(
    parameter AWIDTH = 14,
    parameter DEPTH  = (1 << AWIDTH)
)
(
    input logic clk,
    input logic [31:0] addr,      // Word address (ALU result)
    input logic [31:0] wd,        // Write data
    input logic we,        // Write enable
    input logic re,        // Read enable
    output logic [31:0] rd         // Read data
);

    reg [31:0] memory [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (we)
            memory[addr[AWIDTH-1:0]] <= wd;
    end

    // Asynchronous read
    always_comb begin
        rd = memory[addr[AWIDTH-1:0]];
    end

endmodule