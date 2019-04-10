module datapath(clock, x_in, y_in, colour_in, reset_n, load_x, load_y, draw, erase, x_out, y_out, colour_out);
	input [7:0] x_in;
	input [6:0] y_in;
	input [2:0] colour_in;
	input clock;
	input reset_n; 
	input load_x; 
	input load_y; 
	input draw; 
	input erase;
	output [7:0] x_out;
	output [6:0] y_out;
	output [2:0] colour_out;
	
	reg [3:0] count;
	
	always @(posedge clock)
	begin
		if (!reset_n)
			count <= 4'b0000;
		else if (draw || erase)
			begin
				if(count == 4'b1111)
					count <= 4'b0000;
				else
					count <= count + 1'b1;
			end
	end
	
	assign x_out = x_in + count[1:0];
	assign y_out = y_in + count[3:2];
	assign colour_out = (draw) ? colour_in : 3'b000;
endmodule
