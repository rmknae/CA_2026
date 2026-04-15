/*
 * Module: instruction_memory
 * Description: 16384-word (32-bit) synchronous-read memory.
 * Initializes from 'imem.hex' for simulation.
 */

module instruction_memory (
    input  logic [31:0] addr, // Byte address from PC
    output logic [31:0] dout  // 32-bit instruction
);

    // Memory array: 16384 rows of 32-bit words
    logic [31:0] mem [0:16383];

    // Load test instructions from a hex file
    initial begin
        $readmemh("imem.hex", mem);
    end

    // Word indexing: Convert 32-bit byte address to word address
    // bits [15:2] effectively divide the address by 4
    assign dout = mem[addr[15:2]];

endmodule