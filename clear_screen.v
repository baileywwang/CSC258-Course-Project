module clear_screen(clock, reset_n, x_out, y_out, colour_out);
	input reset_n; 
	input clock;
	output [7:0] x_out;
	output [6:0] y_out;
	output [2:0] colour_out;
	reg [7:0] x_count;
	reg [6:0] y_count;
	reg [5:0] counter;
	
	always @(posedge clock)
		begin
			if (!reset_n)
				begin
					x_count <= 8'd0;
					y_count <= 7'd0;
					counter <= 6'd43;					
				end
			else if (counter == 6'd0)
				begin
					counter <= 6'd43;					
					if (y_count == 7'd120)
						begin
							y_count <= 7'd0;
							x_count <= 8'd0;
						end
					else if (x_count == 8'd160)
						begin
							x_count <= 8'd0;
							y_count <= y_count + 7'd1;
						end
					else
						x_count <= x_count + 8'd1;
				end
			else
				counter <= counter - 6'd1;
		end
		
	assign x_out = x_count;
	assign y_out = y_count;
	assign colour_out = 3'b000;
endmodule
