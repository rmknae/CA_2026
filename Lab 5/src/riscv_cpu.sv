/*
 * Module: riscv_cpu
 * Updated for Experiment 5: Full Single-Cycle Datapath.
 */

`include "opcode.vh"

module riscv_cpu #(
    parameter RESET_PC = 32'h00000000
) (
    input  logic clk,
    input  logic rst
);

    // --- Internal Signals ---
    logic [31:0] pc_current, pc_next, pc_plus_4, br_target;
    logic [31:0] instruction, imm_ext;
    logic [31:0] reg_data1, reg_data2, alu_operand2, alu_result;
    logic [31:0] mem_data_out, writeback_data;

    // Control Signals
    logic [1:0] alu_op;
    logic [3:0] alu_sel;
    logic       reg_write, alu_src, mem_read, mem_write, mem_to_reg;
    logic       branch, jump, lui_sel, zero;
    logic       take_branch;

    // --- 1. Instruction Fetch Unit (IFU) ---
    pc_reg pc_inst (
        .clk(clk), .rst(rst),
        .pc_in(pc_next),
        .pc_out(pc_current)
    );

    instruction_memory imem_inst (
        .addr(pc_current),
        .dout(instruction)
    );

    // --- Combinational Logic Block ---
    always_comb begin
        pc_plus_4   = pc_current + 32'd4;
        br_target   = pc_current + imm_ext;

        // Branch decision
        if (instruction[14:12] == `FNC_BEQ)
            take_branch = zero;
        else if (instruction[14:12] == `FNC_BNE)
            take_branch = ~zero;
        else
            take_branch = 1'b0;

        // PC update logic
        if (jump || (branch && take_branch))
            pc_next = br_target;
        else
            pc_next = pc_plus_4;
    end

    // --- 2. Instruction Decode & Control ---
    first_level_controller main_ctrl (
        .opcode(instruction[6:0]),
        .ALUOp(alu_op), .RegWrite(reg_write), .ALUSrc(alu_src),
        .MemRead(mem_read), .MemWrite(mem_write), .MemtoReg(mem_to_reg),
        .Branch(branch), .Jump(jump), .LUISel(lui_sel)
    );

    imm_gen immediate_unit (
        .instruction(instruction),
        .immediate(imm_ext)
    );

    ASYNC_RAM_1W2R #(.DWIDTH(32), .AWIDTH(5)) register_file (
        .clk(clk),
        .we0(reg_write && (instruction[11:7] != 5'd0)),
        .addr0(instruction[11:7]), .d0(writeback_data),
        .addr1(instruction[19:15]), .q1(reg_data1),
        .addr2(instruction[24:20]), .q2(reg_data2)
    );

    // --- 3. Execution Unit (EX) ---
    always_comb begin
        if (alu_src)
            alu_operand2 = imm_ext;
        else
            alu_operand2 = reg_data2;
    end

    alu_controller alu_ctrl_unit (
        .ALUOp(alu_op),
        .func3(instruction[14:12]), .func7(instruction[31:25]),
        .alu_operation(alu_sel)
    );

    alu main_alu (
        .operand1(reg_data1), .operand2(alu_operand2),
        .alu_operation(alu_sel), .result(alu_result),
        .zero(zero)
    );

    // --- 4. Data Memory Unit (MEM) ---
    ASYNC_RAM_1W2R #(.DWIDTH(32), .AWIDTH(14)) data_memory (
        .clk(clk), .we0(mem_write),
        .addr0(alu_result[15:2]), .d0(reg_data2),
        .addr1(alu_result[15:2]), .q1(mem_data_out),
        .addr2(14'd0), .q2()
    );

    // --- 5. Write-Back Unit (WB) ---
    always_comb begin
        if (lui_sel)
            writeback_data = imm_ext;
        else if (jump)
            writeback_data = pc_plus_4;
        else if (mem_to_reg)
            writeback_data = mem_data_out;
        else
            writeback_data = alu_result;
    end

endmodule