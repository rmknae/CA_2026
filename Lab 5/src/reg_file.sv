/*
 * reg_file.sv
 * 32x32 RISC-V Register File
 *
 * - 32 registers (x0..x31), each 32 bits wide
 * - Register x0 is hardwired to zero (write to x0 is ignored)
 * - Two asynchronous read ports (rs1, rs2)
 * - One synchronous write port (rd)
 *
 * The internal array is named 'Registers' to match testbench access:
 *   `REGFILE_PATH.Registers[i]  where `REGFILE_PATH = cpu.reg_file
 *
 * This module implements the same functionality as ASYNC_RAM_1W2R
 * instantiated with DWIDTH=32, AWIDTH=5, DEPTH=32.
 */

module reg_file
(
    input  logic        clk,
    input  logic [4:0]  rs1,    // Read address 1
    input  logic [4:0]  rs2,    // Read address 2
    input  logic [4:0]  rd,     // Write address
    input  logic [31:0] wd,     // Write data
    input  logic        we,     // Write enable
    output logic [31:0] rd1,    // Read data 1
    output logic [31:0] rd2     // Read data 2
);

    (* ram_style = "distributed" *) reg [31:0] Registers [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            Registers[i] = 32'b0;
    end

    // Synchronous write - x0 is hardwired to zero, never written
    always @(posedge clk) begin
        if (we && rd != 5'b0)
            Registers[rd] <= wd;
    end

    // Combinational reads (asynchronous behavior)
    always_comb begin
        rd1 = (rs1 == 5'b0) ? 32'b0 : Registers[rs1];
        rd2 = (rs2 == 5'b0) ? 32'b0 : Registers[rs2];
    end

endmodule