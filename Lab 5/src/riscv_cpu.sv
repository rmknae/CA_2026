/*
 * riscv_cpu.sv
 * Single-Cycle RISC-V Processor (RV32I subset)
 *
 * Supported instructions:
 *   R-type : add, sub, and, or, xor, sll, srl, sra, slt, sltu
 *   I-type : addi, andi, ori, xori, slti, sltiu, slli, srli, srai, lw, jalr
 *   S-type : sw
 *   B-type : beq, bne
 *   J-type : jal
 *   U-type : lui, auipc
 *
 * ALUOp encoding:
 *   10 = R-type
 *   11 = I-type arithmetic
 *   00 = Load/Store (ADD for address)
 *   01 = Branch (SUB for comparison)
 *
 * PC starts at 0x1000_0000
 * IMEM is word-addressed with word_index = (PC - 0x1000_0000) >> 2
 * DMEM is word-addressed with word_index = ALU_result[13:0]
 */
`include "opcode.vh"

module riscv_cpu
(
    input logic clk,
    input logic rst
);

    // -----------------------------------------------------------------------
    // Internal wires / signals
    // -----------------------------------------------------------------------

    // PC
    logic [31:0] pc;
    logic [31:0] pc_plus4;
    logic [31:0] pc_next;
    logic [31:0] pc_branch;
    logic [31:0] pc_jump;
    logic [31:0] pc_jumpr;

    // Instruction
    logic [31:0] instruction;

    // Instruction fields
    logic [6:0]  opcode;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [2:0]  func3;
    logic [6:0]  func7;

    // Register file
    logic [31:0] reg_rd1, reg_rd2;
    logic [31:0] reg_wd;
    logic        reg_we;

    // Immediate generator
    logic [31:0] immediate;

    // ALU
    logic [31:0] alu_op1, alu_op2;
    logic [3:0]  alu_operation;
    logic [31:0] alu_result;
    logic        alu_zero;

    // Data memory
    logic [31:0] dmem_rd;

    // Control signals
    logic [1:0]  ALUOp;
    logic        ALUSrc;
    logic [1:0]  MemtoReg;
    logic        RegWrite;
    logic        MemRead;
    logic        MemWrite;
    logic        Branch;
    logic        Jump;
    logic        JumpR;
    logic        LUI;
    logic        AUIPC;

    // Branch taken logic
    logic        branch_taken;

    // -----------------------------------------------------------------------
    // PC Register
    // -----------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            pc <= 32'h0000_0000;
        else
            pc <= pc_next;
    end

    // -----------------------------------------------------------------------
    // PC computation
    // -----------------------------------------------------------------------
    assign pc_plus4  = pc + 32'd4;
    assign pc_branch = pc + immediate;           // Branch: PC + sign-ext(imm)
    assign pc_jump   = pc + immediate;           // JAL:    PC + sign-ext(imm)
    assign pc_jumpr  = (reg_rd1 + immediate) & ~32'h1; // JALR: (rs1 + imm) & ~1

    // Branch condition per func3
    always_comb begin
        case (func3)
            `FNC_BEQ  : branch_taken = alu_zero;            // rs1 == rs2
            `FNC_BNE  : branch_taken = ~alu_zero;           // rs1 != rs2
            `FNC_BLT  : branch_taken = alu_result[31];      // signed less than
            `FNC_BGE  : branch_taken = ~alu_result[31] | alu_zero; // signed >=
            `FNC_BLTU : branch_taken = ~alu_zero & (alu_result == 32'd1); // unsigned <
            `FNC_BGEU : branch_taken = ~(alu_result == 32'd1) | alu_zero; // unsigned >=
            default   : branch_taken = 1'b0;
        endcase
    end

    // PC next select
    always_comb begin
        if (Jump)
            pc_next = pc_jump;
        else if (JumpR)
            pc_next = pc_jumpr;
        else if (Branch && branch_taken)
            pc_next = pc_branch;
        else
            pc_next = pc_plus4;
    end

    // -----------------------------------------------------------------------
    // Instruction Memory
    // -----------------------------------------------------------------------
    imem imem (
        .pc          (pc),
        .instruction (instruction)
    );

    // -----------------------------------------------------------------------
    // Instruction field decode
    // -----------------------------------------------------------------------
    assign opcode   = instruction[6:0];
    assign rd_addr  = instruction[11:7];
    assign func3    = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign func7    = instruction[31:25];

    // -----------------------------------------------------------------------
    // Main Controller (First-Level)
    // -----------------------------------------------------------------------
    main_controller main_ctrl (
        .opcode   (opcode),
        .ALUOp    (ALUOp),
        .ALUSrc   (ALUSrc),
        .MemtoReg (MemtoReg),
        .RegWrite (RegWrite),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .Branch   (Branch),
        .Jump     (Jump),
        .JumpR    (JumpR),
        .LUI      (LUI),
        .AUIPC    (AUIPC)
    );

    // -----------------------------------------------------------------------
    // Register File
    // -----------------------------------------------------------------------
    reg_file reg_file (
        .clk  (clk),
        .rs1  (rs1_addr),
        .rs2  (rs2_addr),
        .rd   (rd_addr),
        .wd   (reg_wd),
        .we   (reg_we),
        .rd1  (reg_rd1),
        .rd2  (reg_rd2)
    );

    assign reg_we = RegWrite;

    // -----------------------------------------------------------------------
    // Immediate Generator
    // -----------------------------------------------------------------------
    imm_gen imm_gen (
        .instruction (instruction),
        .immediate   (immediate)
    );

    // -----------------------------------------------------------------------
    // ALU Controller (Second-Level)
    // -----------------------------------------------------------------------
    alu_controller alu_ctrl (
        .ALUOp        (ALUOp),
        .func3        (func3),
        .func7        (func7),
        .alu_operation(alu_operation)
    );

    // -----------------------------------------------------------------------
    // ALU input muxes
    // operand1: rs1 value, or PC for AUIPC
    // operand2: rs2 value, or immediate if ALUSrc=1
    // -----------------------------------------------------------------------
    assign alu_op1 = AUIPC ? pc : reg_rd1;
    assign alu_op2 = ALUSrc ? immediate : reg_rd2;

    // -----------------------------------------------------------------------
    // ALU
    // -----------------------------------------------------------------------
    alu alu (
        .operand1     (alu_op1),
        .operand2     (alu_op2),
        .alu_operation(alu_operation),
        .result       (alu_result),
        .zero         (alu_zero)
    );

    // -----------------------------------------------------------------------
    // Data Memory
    // -----------------------------------------------------------------------
    dmem dmem (
        .clk  (clk),
        .addr (alu_result),
        .wd   (reg_rd2),
        .we   (MemWrite),
        .re   (MemRead),
        .rd   (dmem_rd)
    );

    // -----------------------------------------------------------------------
    // Write-Back Mux
    // MemtoReg: 00 = ALU result
    //           01 = Data memory
    //           10 = PC+4  (JAL/JALR return address)
    //           11 = Immediate (LUI)
    // -----------------------------------------------------------------------
    always_comb begin
        case (MemtoReg)
            2'b00   : reg_wd = alu_result;
            2'b01   : reg_wd = dmem_rd;
            2'b10   : reg_wd = pc_plus4;
            2'b11   : reg_wd = immediate;    // LUI: immediate already has {imm20,12'b0}
            default : reg_wd = alu_result;
        endcase
    end

endmodule
