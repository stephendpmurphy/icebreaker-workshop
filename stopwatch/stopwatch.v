// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Project entry point
module top (
	input  CLK,
	input  BTN_N, BTN1, BTN2, BTN3,
	output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);
	// 7 segment control line bus
	wire [7:0] seven_segment;

	// Assign 7 segment control line bus to Pmod pins
	assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = seven_segment;

	// Display value register and increment bus
	wire [7:0] display_value_inc;
	reg [7:0] display_value = 0;
	reg [0:0] running = 0;
	reg [7:0] lap_value = 0;
	reg [4:0] lap_timeout = 0;
	reg [0:0] flashLap = 0;

	wire dimmerPulse;
	wire divClkPulse;
	wire lapPulse;
	reg flashDisp = 0;

	// Clock divider and pulse registers
	reg clkdiv_pulse = 0;

	// Synchronous logic
	always @(posedge CLK) begin
		if (BTN3) begin
			running <= !running;
		end

		if (BTN2) begin
			lap_value <= display_value;
			flashDisp <= 1;
		end else begin
			flashDisp <= 0;
		end
	end

	always @(posedge divClkPulse) begin
		if(running) begin
			display_value <= display_value_inc;
		end

		if(flashDisp) begin
			lap_timeout <= 20;
		end

		if(lap_timeout > 0) begin
			lap_timeout <= lap_timeout - 1;
		end
	end

	divider clkDiv1_2M (
		.clk(CLK),
		.divider(25'd1200000),
		.pulse(divClkPulse)
	);

	PWM lapFlashTimer(
        .clk(CLK),
        .period(25'd4800000),
        .target(25'd2400000),
        .dout(lapPulse)
    );

	PWM backlightDriver(
        .clk(CLK),
        .period(25'd5000),
        .target(25'd5000),
        .dout(dimmerPulse)
    );

	// assign display_value_inc = display_value + 8'b1;
	bcd8_increment incrementBcd8 (
		.din(display_value),
		.dout(display_value_inc)
	);

	// 7 segment display control Pmod 1A
	seven_seg_ctrl seven_segment_ctrl (
		.CLK(CLK),
		.EN(dimmerPulse),
		.din(lap_timeout ? (lapPulse ? lap_value[7:0] : 8'hFF) : display_value[7:0]),
		.dout(seven_segment)
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

// BCD (Binary Coded Decimal) counter
module bcd8_increment (
	input [7:0] din,
	output reg [7:0] dout
);
	always @* begin
		case (1'b1)
			din[7:0] == 8'h 99:
				dout = 0;
			din[3:0] == 4'h 9:
				dout = {din[7:4] + 4'd 1, 4'h 0};
			default:
				dout = {din[7:4], din[3:0] + 4'd 1};
		endcase
	end
endmodule

// Seven segment controller
// Switches quickly between the two parts of the display
// to create the illusion of both halves being illuminated
// at the same time.
module seven_seg_ctrl (
	input CLK,
	input EN,
	input [7:0] din,
	output reg [7:0] dout
);
	wire [6:0] lsb_digit;
	wire [6:0] msb_digit;

	seven_seg_hex msb_nibble (
		.din(din[7:4]),
		.dout(msb_digit)
	);

	seven_seg_hex lsb_nibble (
		.din(din[3:0]),
		.dout(lsb_digit)
	);

	reg [9:0] clkdiv = 0;
	reg clkdiv_pulse = 0;
	reg msb_not_lsb = 0;

	always @(posedge CLK) begin
		clkdiv <= clkdiv + 1;
		clkdiv_pulse <= &clkdiv;
		msb_not_lsb <= msb_not_lsb ^ clkdiv_pulse;

			if (!EN) begin
				dout[7:0] = 8'hFF;
			end else if (clkdiv_pulse) begin
				if ( din == 8'hFF ) begin
					dout[7:0] = 8'hFF;
				end else if (msb_not_lsb) begin
					dout[6:0] <= ~msb_digit;
					dout[7] <= 0;
				end else begin
					dout[6:0] <= ~lsb_digit;
					dout[7] <= 1;
			end
		end
	end
endmodule

// Convert 4bit numbers to 7 segments
module seven_seg_hex (
	input [3:0] din,
	output reg [6:0] dout
);
	always @*
		case (din)
			4'h0: dout = 7'b 0111111;
			4'h1: dout = 7'b 0000110;
			4'h2: dout = 7'b 1011011;
			4'h3: dout = 7'b 1001111;
			// 4'h3: dout = FIXME;
			4'h4: dout = 7'b 1100110;
			4'h5: dout = 7'b 1101101;
			4'h6: dout = 7'b 1111101;
			4'h7: dout = 7'b 0000111;
			4'h8: dout = 7'b 1111111;
			// 4'h8: dout = FIXME;
			4'h9: dout = 7'b 1101111;
			4'hA: dout = 7'b 1110111;
			4'hB: dout = 7'b 1111100;
			4'hC: dout = 7'b 0111001;
			4'hD: dout = 7'b 1011110;
			4'hE: dout = 7'b 1111001;
			4'hF: dout = 7'b 1110001;
			default: dout = 7'b 1000000;
		endcase
endmodule