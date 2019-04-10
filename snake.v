module snake
	(CLOCK_50,		// On Board 50 MHz
	 SW,				// Swiches for selecting rate.
	 KEY,				// Keys for changing directions.
	 VGA_CLK,		//	VGA Clock
	 VGA_HS,			//	VGA H_SYNC
	 VGA_VS,			//	VGA V_SYNC
	 VGA_BLANK_N,	//	VGA BLANK
	 VGA_SYNC_N,	//	VGA SYNC
	 VGA_R,			//	VGA Red[9:0]
	 VGA_G,			//	VGA Green[9:0]
	 VGA_B,			//	VGA Blue[9:0]
	 HEX0, 
	 HEX1
	 );

	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output VGA_CLK;   			
	output VGA_HS;					
	output VGA_VS;					
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	output [6:0] HEX0;
	output [6:0] HEX1;
	
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire [7:0] score;
	wire writeEn;

	vga_adapter VGA(
		.resetn(~SW[0]),
		.clock(CLOCK_50),
		.colour(colour),
		.x(x),
		.y(y),
		.plot(writeEn),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";

	combine u0(
		.CLOCK_50(CLOCK_50),
		.reset_n(~SW[0]),
		.level(SW[9:8]),
		.up(~KEY[3]),
		.down(~KEY[2]),
		.left(~KEY[1]),
		.right(~KEY[0]),
		.x_out(x),
		.y_out(y),
		.colour_out(colour),
		.plot(writeEn),
		.score(score)
		);
	
	hex_decoder H0(
		.hex_digit(score[3:0]), 
		.segments(HEX0)
	);
 
	hex_decoder H1(
		.hex_digit(score[7:4]), 
		.segments(HEX1)
	);

endmodule


module combine(CLOCK_50, reset_n, level, up, down, left, right, x_out, y_out, colour_out, plot, score);
	input CLOCK_50;
	input reset_n; 
	input up; 
	input down; 
	input left; 
	input right;
	input [1:0]level;
	output [7:0]x_out;
	output [6:0]y_out;
	output [2:0]colour_out;
	output plot;
	output [7:0]score;
	
	wire [7:0] x_in;
	wire [6:0] y_in;
	wire [2:0] colour_in;
	wire load_x, load_y, draw, erase;
	wire [7:0] data_x;
	wire [6:0] data_y;
	wire [2:0] data_colour;
	wire [7:0] restart_x;
	wire [6:0] restart_y;
	wire [2:0] restart_colour;
	wire restart;
	reg [23:0] rate;

	always@(*)
	begin
		case(level)
			2'b00: rate <= 24'd12_500_000;
			2'b01: rate <= 24'd10_000_000;
			2'b10: rate <= 24'd7_500_000;
			2'b11: rate <= 24'd5_000_000;
		endcase
	end				

	control_module u0(
		.CLOCK_50(CLOCK_50), 
		.reset_n(reset_n), 
		.up(up), 
		.down(down), 
		.left(left), 
		.right(right), 
		.x_count(x_in), 
		.y_count(y_in), 
		.colour(colour_in), 
		.load_x(load_x), 
		.load_y(load_y), 
		.draw(draw), 
		.erase(erase), 
		.plot(plot),
		.restart_game(restart),
		.rate(rate),
		.score(score)
	);
	
				 
	datapath u1(
		.x_in(x_in), 
		.y_in(y_in), 
		.colour_in(colour_in), 
		.clock(CLOCK_50), 
		.reset_n(reset_n), 
		.load_x(load_x), 
		.load_y(load_y), 
		.draw(draw), 
		.erase(erase), 
		.x_out(data_x), 
		.y_out(data_y), 
		.colour_out(data_colour)
	);
					
	clear_screen u2(
		.reset_n(reset_n), 
		.clock(CLOCK_50), 
		.x_out(restart_x), 
		.y_out(restart_y), 
		.colour_out(restart_colour)
	);
	
	assign colour_out = (restart) ? 3'b000: data_colour;
	assign x_out = (restart) ? restart_x : data_x;
	assign y_out = (restart) ? restart_y : data_y;
endmodule
