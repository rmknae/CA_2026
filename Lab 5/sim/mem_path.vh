// Memory hierarchy paths for testbench access
`ifndef MEM_PATH
`define MEM_PATH

// REGFILE_PATH: access as `REGFILE_PATH.Registers[i]
`define REGFILE_PATH  cpu.reg_file

// IMEM_PATH: access as `IMEM_PATH.memory[i]
`define IMEM_PATH     cpu.imem

// DMEM_PATH: access as `DMEM_PATH.memory[i]
`define DMEM_PATH     cpu.dmem

`endif // MEM_PATH
