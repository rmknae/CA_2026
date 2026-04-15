/*
 * Module: riscv_cpu_tb
 * Description: Self-testing testbench for Tasks 1-4.
 * Verifies I-type, R-type, and Memory Access (LW/SW) operations.
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
        $display("=== Starting Full CPU Verification (Tasks 1-4) ===");
        
        // 1. System Reset
        rst = 1;
        #20 rst = 0;

        // 2. Wait for Completion Flag (x20)
        wait(dut.register_file.mem[20] == 32'h1);
        #10; // Allow write-back to settle

        // 3. Verify Task 3: I-type Initialization
        if (dut.register_file.mem[1] !== 32'd10) begin
            $display("[FAIL] Task 3 (ADDI): x1 expected 10, got %0d", dut.register_file.mem[1]);
            errors++;
        end

        // 4. Verify Task 1/2: R-type Arithmetic
        if (dut.register_file.mem[3] !== 32'd15 || dut.register_file.mem[4] !== 32'd5) begin
            $display("[FAIL] Task 1/2 (R-type): Math results incorrect");
            errors++;
        end

        // 5. Verify Task 4: Memory Access (LW/SW)
        // SW stored 15 at Mem[8], LW should load into x5
        if (dut.register_file.mem[5] !== 32'd15) begin
            $display("[FAIL] Task 4 (LW/SW): x5 expected 15 from memory, got %0d", dut.register_file.mem[5]);
            errors++;
        end

        // 6. Final Report
        if (errors == 0) begin
            $display("***************************************************");
            $display("* ALL TASKS (1-4) PASSED SUCCESSFULLY            *");
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
        $display("!!! TIMEOUT: Processor failed to set x20 flag !!!");
        $finish;
    end

endmodule