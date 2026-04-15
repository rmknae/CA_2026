/*
 * Module: riscv_cpu
 * Description: Single-Cycle RISC-V Datapath for Task 4.
 * Supports R-type, I-type Arithmetic, Load, and Store instructions.
 */

`include "opcode.vh"

module riscv_cpu #(
    parameter RESET_PC = 32'h00000000
) (
    input  logic clk,
    input  logic rst
);

    // --- Internal Signals ---
    logic [31:0] pc_current, pc_next;
    logic [31:0] instruction;
    logic [31:0] imm_ext;
    logic [31:0] reg_data1, reg_data2;
    logic [31:0] alu_operand2;
    logic [31:0] alu_result;
    logic [31:0] mem_data_out;
    logic [31:0] writeback_data;
    
    // Control Signals
    logic [1:0] alu_op;
    logic [3:0] alu_sel;
    logic       reg_write, alu_src, mem_read, mem_write, mem_to_reg;

    // --- 1. Instruction Fetch Unit (IFU) ---
    pc_reg pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(pc_next),
        .pc_out(pc_current)
    );

    assign pc_next = pc_current + 32'd4;

    instruction_memory imem_inst (
        .addr(pc_current),
        .dout(instruction)
    );

    // --- 2. Instruction Decode & Control Unit ---
    first_level_controller main_ctrl (
        .opcode(instruction[6:0]),
        .ALUOp(alu_op),
        .RegWrite(reg_write),
        .ALUSrc(alu_src),
        .MemRead(mem_read),
        .MemWrite(mem_write),
        .MemtoReg(mem_to_reg)
    );

    imm_gen immediate_unit (
        .instruction(instruction),
        .immediate(imm_ext)
    );

    // Register File (ASYNC_RAM_1W2R)
    ASYNC_RAM_1W2R #(
        .DWIDTH(32),
        .AWIDTH(5)
    ) register_file (
        .clk(clk),
        .we0(reg_write && (instruction[11:7] != 5'd0)), // x0 protection
        .addr0(instruction[11:7]), 
        .d0(writeback_data),           
        .addr1(instruction[19:15]),
        .q1(reg_data1),
        .addr2(instruction[24:20]),
        .q2(reg_data2)
    );

    // --- 3. Execution Unit (EX) ---
    assign alu_operand2 = (alu_src) ? imm_ext : reg_data2;

    alu_controller alu_ctrl_unit (
        .ALUOp(alu_op),
        .func3(instruction[14:12]),
        .func7(instruction[31:25]),
        .alu_operation(alu_sel)
    );

    alu main_alu (
        .operand1(reg_data1),
        .operand2(alu_operand2),
        .alu_operation(alu_sel),
        .result(alu_result),
        .zero() 
    );

    // --- 4. Data Memory Unit (MEM) ---
    ASYNC_RAM_1W2R #(
        .DWIDTH(32),
        .AWIDTH(14) // 16KB memory
    ) data_memory (
        .clk(clk),
        .we0(mem_write),
        .addr0(alu_result[15:2]), // Word-aligned
        .d0(reg_data2),           // Store data from rs2
        .addr1(alu_result[15:2]),
        .q1(mem_data_out),
        .addr2(14'd0), // Unused
        .q2()
    );

    // --- 5. Write-Back Selection (WB) ---
    assign writeback_data = (mem_to_reg) ? mem_data_out : alu_result;

endmodule