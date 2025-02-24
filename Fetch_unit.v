`timescale 1 ns/1 ps

module fetch_unit_with_reg(
    input  wire       clk,
    input  wire       reset,
    input  wire       branch,       // Branch signal: when true, use branch_addr
    input  wire       jump,         // Jump signal: when true, use jump_target
    input  wire [9:0] branch_addr,  // Branch target (PC+1 + immediate)
    input  wire [9:0] jump_target,  // Jump target (direct 10-bit address)
    output wire [9:0] pc_out        // Current PC output
);

    // Calculate PC+1
    wire [9:0] pc_plus_one;
    assign pc_plus_one = pc_out + 10'd1;
    
    // Next PC selection:
    // Priority: if jump is asserted, load jump_target;
    // otherwise if branch is asserted, load branch_addr;
    // else increment PC.
    wire [9:0] next_pc;
    assign next_pc = jump ? jump_target : (branch ? branch_addr : pc_plus_one);
    
    // Instantiate the 10-bit register that holds the PC.
    register_10bit pc_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .din(next_pc),
        .dout(pc_out)
    );
    
endmodule

module tb_fetch_unit_with_reg;
    // Inputs to the fetch unit
    reg         clk;
    reg         reset;
    reg         branch;       
    reg         jump;         
    reg  [9:0]  branch_addr;  
    reg  [9:0]  jump_target;  
    // Output from the fetch unit
    wire [9:0]  pc_out;

    // Instantiate the fetch unit under test
    fetch_unit_with_reg dut (
        .clk(clk),
        .reset(reset),
        .branch(branch),
        .jump(jump),
        .branch_addr(branch_addr),
        .jump_target(jump_target),
        .pc_out(pc_out)
    );
    
    // Clock generation: Toggle every 5 ns for a 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Use $monitor or $display to track PC changes over time
    initial begin
        $monitor("Time=%0t | reset=%b branch=%b jump=%b | branch_addr=%d jump_target=%d | pc_out=%d",
                 $time, reset, branch, jump, branch_addr, jump_target, pc_out);
    end

    // Stimulus: test normal increments, then branch, then jump
    initial begin
        // -------- Reset Phase --------
        reset        = 1;
        branch       = 0;
        jump         = 0;
        branch_addr  = 10'd100;
        jump_target  = 10'd500;
        
        // Assert reset for 15 ns
        #15;
        reset = 0;   // Deassert reset, PC should start incrementing from 0
        #20;         // Let it increment a couple cycles

        // -------- Test Branch --------
        // When branch is asserted, PC should load branch_addr on the next clock edge
        $display("\n--- Asserting BRANCH to load PC with branch_addr = %d ---", branch_addr);
        branch = 1;
        #10;
        branch = 0;  // Deassert branch
        #40;         // Wait a few cycles to observe increments again

        // -------- Test Jump --------
        // When jump is asserted, PC should load jump_target on the next clock edge
        $display("\n--- Asserting JUMP to load PC with jump_target = %d ---", jump_target);
        jump = 1;
        #10;
        jump = 0;    // Deassert jump
        #40;         // Wait a few cycles to observe increments again

        // End simulation
        $finish;
    end
endmodule


