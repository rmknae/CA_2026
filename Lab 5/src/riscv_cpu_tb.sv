 /*
 * Module: riscv_cpu_tb
 * Updated for Experiment 5: Verifies B, J, and U type instructions.
 */

`timescale 1ns / 1ps

module riscv_cpu_tb();

    logic clk;
    logic rst;
    integer errors = 0;

    // Instantiate the CPU
    riscv_cpu dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("=== Starting Experiment 5 Verification ===");
        
        // 1. System Reset
        rst = 1;
        #20 rst = 0;

        // 2. Wait for Completion Flag (x20)
        wait(dut.register_file.mem[20] == 32'h1);
        #10;

        // 3. Verify B-type (BEQ): Check if x3 and x4 were skipped
        if (dut.register_file.mem[3] !== 32'd0 || dut.register_file.mem[4] !== 32'd0) begin
            $display("[FAIL] BEQ: Instructions that should have been skipped were executed");
            errors++;
        end
        if (dut.register_file.mem[5] !== 32'd31) begin
            $display("[FAIL] BEQ: Branch target not reached correctly");
            errors++;
        end

        // 4. Verify B-type (BNE): Check if x6 was updated
        if (dut.register_file.mem[6] !== 32'd42) begin
            $display("[FAIL] BNE: Conditional branch logic failed");
            errors++;
        end

        // 5. Verify U-type (LUI): Check x7 for upper bits
        if (dut.register_file.mem[7] !== 32'h12345000) begin
            $display("[FAIL] LUI: Expected 0x12345000, got %h", dut.register_file.mem[7]);
            errors++;
        end

        // 6. Verify J-type (JAL): Check if x8 was skipped and x9 has return address
        if (dut.register_file.mem[8] !== 32'd0) begin
            $display("[FAIL] JAL: Jump failed to skip instruction");
            errors++;
        end
        if (dut.register_file.mem[9] == 32'd0) begin
            $display("[FAIL] JAL: Return address (link) not saved in x9");
            errors++;
        end

        // Final Report
        if (errors == 0) begin
            $display("***************************************************");
            $display("* ALL EXPERIMENT 5 TESTS PASSED SUCCESSFULLY     *");
            $display("***************************************************");
        end else begin
            $display("***************************************************");
            $display("* VERIFICATION FAILED: %0d ERRORS FOUND           *", errors);
            $display("***************************************************");
        end

        $finish;
    end

    // Timeout safety
    initial begin
        #5000;
        $display("!!! TIMEOUT: Processor failed to complete !!!");
        $finish;
    end

endmodule