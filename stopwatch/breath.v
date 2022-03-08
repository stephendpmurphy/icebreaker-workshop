// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Project entry point
module top (
    input  CLK,
    output LED1, LED2, LED3, LED4, LED5
    );

    reg [24:0] pwmTarget = 50;
    wire pwmPulse;
    wire divClkPulse;
    assign {LED1, LED2, LED3, LED4, LED5} = {5{pwmPulse}};
    reg upCount = 1;

    always @(posedge divClkPulse) begin
        if( upCount ) begin
            pwmTarget <= pwmTarget + 1;

            if( pwmTarget == 5000 ) begin
                upCount <= !upCount;
            end
        end else begin
            pwmTarget <= pwmTarget - 1;

            if( pwmTarget == 50 ) begin
                upCount <= !upCount;
            end
        end
    end

    divider clkDivider(
        .clk(CLK),
        .divider(25'd6000),
        .pulse(divClkPulse),
    );

    PWM pwmDriver(
        .clk(CLK),
        .period(25'd5000),
        .target(pwmTarget),
        .dout(pwmPulse)
    );
endmodule

module PWM (
    input clk,
    input [24:0] period,
    input [24:0] target,
    output reg dout,
    );

    reg [24:0] cnt = 0;

    always @(posedge clk) begin
        cnt <= cnt + 1;

        if(cnt <= target) begin
            dout <= 1;
        end else begin
            dout <= 0;
        end

        if(cnt == period) begin
            cnt <= 0;
            dout <= 1;
        end
    end
endmodule

module divider (
    input clk,
    input [24:0] divider,
    output reg[0:0] pulse,
    );

    reg [24:0] clkCnt;

    always @(posedge clk) begin
        if(clkCnt == divider) begin
            pulse <= 1;
            clkCnt <= 0;
        end else begin
            clkCnt <= clkCnt + 1;
            pulse <= 0;
        end
    end
endmodule