/*
 * Module: pc_reg
 * Description: 32-bit register to store the Program Counter (PC).
 * Updates on the positive edge of the clock.
 */

module pc_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc_in,
    output logic [31:0] pc_out
);

    // Synchronous register with asynchronous/synchronous reset
    always_ff @(posedge clk) begin
        if (rst) 
            pc_out <= 32'h00000000; // Default Reset Address
        else 
            pc_out <= pc_in;
    end

endmodule