module vending_machine_dual_mode (
    input wire clk,
    input wire reset,
    input wire [2:0] coin,        // 001=₹5, 010=₹10, 011=₹50, 100=₹100, 101=₹500
    input wire buy,               // Buy request
    input wire refund,            // Refund request
    input wire mode_select,       // 0 = Manual mode, 1 = Auto-bulk mode
    output reg product,           // Product dispense signal
    output reg refund_signal,     // Refund processed signal
    output reg [15:0] balance,    // Current balance
    output reg [15:0] change      // Returned change after auto-buy/refund
);

    // FSM states using parameter instead of typedef enum
    parameter IDLE     = 2'b00;
    parameter COLLECT  = 2'b01;
    parameter DISPENSE = 2'b10;
    parameter REFUND   = 2'b11;

    reg [1:0] current_state, next_state;

    // Coin decoder function
    function [15:0] coin_value;
        input [2:0] c;
        begin
            case (c)
                3'b001: coin_value = 5;
                3'b010: coin_value = 10;
                3'b011: coin_value = 50;
                3'b100: coin_value = 100;
                3'b101: coin_value = 500;
                default: coin_value = 0;
            endcase
        end
    endfunction

    // State register
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Output and balance logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            product <= 0;
            refund_signal <= 0;
            change <= 0;
            balance <= 0;
        end else begin
            product <= 0;
            refund_signal <= 0;
            change <= 0;

            case (current_state)
                IDLE: begin
                    if (coin != 3'b000)
                        balance <= coin_value(coin);
                end

                COLLECT: begin
                    if (coin != 3'b000)
                        balance <= balance + coin_value(coin);
                end

                DISPENSE: begin
                    if (mode_select == 1) begin  // Auto Mode
                        if (balance >= 100) begin
                            product <= 1;
                            balance <= balance - 100;
                        end else begin
                            change <= balance;
                            balance <= 0;
                        end
                    end else begin  // Manual Mode
                        if (balance >= 100) begin
                            product <= 1;
                            balance <= balance - 100;
                        end
                    end
                end

                REFUND: begin
                    refund_signal <= 1;
                    change <= balance;
                    balance <= 0;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE:
                next_state = (coin != 3'b000) ? COLLECT : IDLE;

            COLLECT:
                if (refund)
                    next_state = REFUND;
                else if (buy && balance >= 100)
                    next_state = DISPENSE;
                else
                    next_state = COLLECT;

            DISPENSE:
                if (mode_select == 1)  // Auto mode: loop dispensing
                    next_state = (balance >= 100) ? DISPENSE : IDLE;
                else                  // Manual mode: single dispense
                    next_state = IDLE;

            REFUND:
                next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

endmodule