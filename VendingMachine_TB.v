`timescale 1ns / 1ps

module tb_vending_machine_dual_mode;

  reg clk, reset;
  reg [2:0] coin;
  reg buy, refund, mode_select;
  wire product, refund_signal;
  wire [15:0] balance, change;

  // DUT Instance
  vending_machine_dual_mode uut (
    .clk(clk),
    .reset(reset),
    .coin(coin),
    .buy(buy),
    .refund(refund),
    .mode_select(mode_select),
    .product(product),
    .refund_signal(refund_signal),
    .balance(balance),
    .change(change)
  );

  // Clock generation: 10ns period
  always #5 clk = ~clk;

  initial begin
    $dumpfile("vending_machine_dual_mode.vcd");
    $dumpvars(0, tb_vending_machine_dual_mode);

    // Initial state
    clk = 0; reset = 1;
    coin = 3'b000;
    buy = 0;
    refund = 0;
    mode_select = 0;

    #10 reset = 0;

    // === Test Case 1: Manual Mode ===
    $display("Manual Mode: Insert ₹500, Buy once");
    mode_select = 0;

    // Insert ₹500
    #10 coin = 3'b101; // ₹500
    #10 coin = 3'b000;

    // Press Buy
    #10 buy = 1;
    #10 buy = 0;

    // Press Buy again
    #20 buy = 1;
    #10 buy = 0;

    // Press Buy third time
    #20 buy = 1;
    #10 buy = 0;

    // Refund remaining balance
    #20 refund = 1;
    #10 refund = 0;

    // === Test Case 2: Auto Mode ===
    $display("Auto Mode: Insert ₹270, Buy");
    mode_select = 1;

    // Insert ₹100
    #20 coin = 3'b100; // ₹100
    #10 coin = 3'b000;

    // Insert ₹100
    #10 coin = 3'b100; // ₹100
    #10 coin = 3'b000;

    // Insert ₹50
    #10 coin = 3'b011; // ₹50
    #10 coin = 3'b000;

    // Insert ₹20 (simulate invalid coin input)
    #10 coin = 3'b110; // Invalid
    #10 coin = 3'b000;

    // Insert ₹20 as two ₹10 coins
    #10 coin = 3'b010;
    #10 coin = 3'b010;
    #10 coin = 3'b000;

    // Press Buy in auto mode
    #20 buy = 1;
    #10 buy = 0;

    #50 $finish;
  end

endmodule