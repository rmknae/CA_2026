/*
 * imem.sv
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

    logic [AWIDTH-1:0] word_addr;

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'b0;
    end

    always_comb begin
        word_addr  = pc >> 2;
        instruction = memory[word_addr];
    end

endmodule