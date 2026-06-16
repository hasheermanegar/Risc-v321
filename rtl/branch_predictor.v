/**
 * Branch Predictor
 * Features:
 * - 1-bit predictor with 512-entry history
 * - Pattern history table (PHT)
 * - Branch target buffer (BTB)
 * - Update on execution
 */

`timescale 1ns / 1ps

module branch_predictor #(
    parameter ADDR_WIDTH = 32,
    parameter HISTORY_BITS = 9,  // 512 entries
    parameter NUM_ENTRIES = 512
) (
    input clk,
    input rst,
    
    // Fetch stage prediction request
    input [ADDR_WIDTH-1:0] pc_fetch,
    
    // Execute stage update
    input branch_taken,
    input [ADDR_WIDTH-1:0] branch_target,
    input update_en,
    
    // Prediction output
    output predicted_taken,
    output [ADDR_WIDTH-1:0] predicted_target
);

    // ============================================================
    // Pattern History Table
    // ============================================================
    
    reg pht [0:NUM_ENTRIES-1];  // 1-bit predictor per entry
    reg [ADDR_WIDTH-1:0] btb [0:NUM_ENTRIES-1];  // Branch Target Buffer
    
    wire [HISTORY_BITS-1:0] pc_hash = pc_fetch[HISTORY_BITS+1:2];
    wire [HISTORY_BITS-1:0] update_hash = branch_target[HISTORY_BITS+1:2];
    
    // ============================================================
    // Prediction (Asynchronous)
    // ============================================================
    
    assign predicted_taken = pht[pc_hash];
    assign predicted_target = btb[pc_hash];
    
    // ============================================================
    // Update (Synchronous)
    // ============================================================
    
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            // Initialize predictor - predict taken for all entries
            for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
                pht[i] <= 1'b1;
                btb[i] <= 32'h00000000;
            end
        end else if (update_en) begin
            // Update PHT with actual branch outcome
            pht[update_hash] <= branch_taken;
            
            // Update BTB with actual target
            if (branch_taken) begin
                btb[update_hash] <= branch_target;
            end
        end
    end
    
endmodule
