/**
 * Memory Module - Combined Instruction & Data Memory
 * Features:
 * - Single-cycle read/write
 * - 4KB address space (1024 x 32-bit words)
 * - Separate instruction and data ports
 */

`timescale 1ns / 1ps

module memory_module #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter INSTR_WIDTH = 32,
    parameter MEM_SIZE = 1024
) (
    input clk,
    input rst,
    
    // Instruction memory interface (read-only)
    input [ADDR_WIDTH-1:0] instr_addr,
    output reg [INSTR_WIDTH-1:0] instr_data,
    
    // Data memory interface (read/write)
    input [ADDR_WIDTH-1:0] data_addr,
    input data_rd_en,
    input data_wr_en,
    input [DATA_WIDTH-1:0] data_wr_data,
    output reg [DATA_WIDTH-1:0] data_rd_data
);

    // Memory array (unified instruction and data space)
    reg [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];
    
    // ============================================================
    // Memory Initialization
    // ============================================================
    
    integer i;
    
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            memory[i] = 32'h00000000;
    end
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < MEM_SIZE; i = i + 1)
                memory[i] <= 32'h00000000;
        end
    end
    
    // ============================================================
    // Instruction Read (Asynchronous)
    // ============================================================
    
    always @(*) begin
        if (instr_addr[ADDR_WIDTH-1:10] == {(ADDR_WIDTH-10){1'b0}})
            instr_data = memory[instr_addr[9:2]];
        else
            instr_data = 32'h00000000;
    end
    
    // ============================================================
    // Data Memory Operations (Synchronous write, async read)
    // ============================================================
    
    always @(posedge clk) begin
        // Write operation
        if (data_wr_en && (data_addr[ADDR_WIDTH-1:10] == {(ADDR_WIDTH-10){1'b0}})) begin
            memory[data_addr[9:2]] <= data_wr_data;
        end
    end
    
    // Asynchronous read
    always @(*) begin
        if (data_rd_en && (data_addr[ADDR_WIDTH-1:10] == {(ADDR_WIDTH-10){1'b0}}))
            data_rd_data = memory[data_addr[9:2]];
        else
            data_rd_data = 32'h00000000;
    end
    
    // ============================================================
    // Program Loading (for simulation)
    // ============================================================
    
    task load_program (
        input string filename
    );
        integer fd, status, i, addr, data;
        begin
            fd = $fopen(filename, "r");
            if (fd) begin
                i = 0;
                while (!$feof(fd) && i < MEM_SIZE) begin
                    status = $fscanf(fd, "%h %h", addr, data);
                    if (status == 2) begin
                        memory[addr] = data;
                    end
                    i = i + 1;
                end
                $fclose(fd);
                $display("Program loaded from %s", filename);
            end else begin
                $display("Error: Could not open file %s", filename);
            end
        end
    endtask
    
endmodule
