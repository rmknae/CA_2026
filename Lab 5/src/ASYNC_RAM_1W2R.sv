/*
 * Multi-port RAM with two asynchronous-read ports, one synchronous-write port.
 * Used as the register file in the RISC-V processor.
 */
module ASYNC_RAM_1W2R
#(
    parameter DWIDTH = 8,               // Data width
    parameter AWIDTH = 8,               // Address width
    parameter DEPTH  = (1 << AWIDTH),   // Memory depth
    parameter MIF_HEX = "",
    parameter MIF_BIN = ""
)
(
    input  logic              clk,
    input  logic [DWIDTH-1:0] d0,       // Write data
    input  logic [AWIDTH-1:0] addr0,    // Write address
    input  logic              we0,      // Write enable
    input  logic [AWIDTH-1:0] addr1,    // Read address 1
    output logic [DWIDTH-1:0] q1,       // Read data 1
    input  logic [AWIDTH-1:0] addr2,    // Read address 2
    output logic [DWIDTH-1:0] q2        // Read data 2
);

    (* ram_style = "distributed" *) reg [DWIDTH-1:0] memory [0:DEPTH-1];

    integer i;
    initial begin
        if (MIF_HEX != "") begin
            $readmemh(MIF_HEX, memory);
        end
        else if (MIF_BIN != "") begin
            $readmemb(MIF_BIN, memory);
        end
        else begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] = 0;
            end
        end
    end

    // Synchronous write
    always @(posedge clk) begin
        if (we0 && addr0 != 0)  // x0 is hardwired to zero
            memory[addr0] <= d0;
    end

    // Asynchronous reads
    assign q1 = (addr1 == 0) ? 32'b0 : memory[addr1];
    assign q2 = (addr2 == 0) ? 32'b0 : memory[addr2];

endmodule
