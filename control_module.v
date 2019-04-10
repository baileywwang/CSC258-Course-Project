module control_module(CLOCK_50, reset_n, up, down, left, right, x_count, y_count, colour, load_x, load_y, draw, erase, plot, restart_game, rate, score);
	input CLOCK_50;
	input reset_n; 
	input up; 
	input down; 
	input left; 
	input right;
	input [23:0] rate;
	output reg [7:0] x_count;
	output reg [6:0] y_count;
	output reg load_x;
	output reg load_y; 
	output reg draw; 
	output reg erase; 
	output reg plot; 
	output reg restart_game;
	output reg [2:0] colour;
	output reg [7:0] score;
	
	reg [1:0] direction; 
	reg [4:0] current_state;
	reg [4:0] next_state;
	reg [14:0] position [0:127];   // The length of the snake is at most 128. 
	reg [14:0] food; 
	reg [19:0] draw_erase_counter; // The counter for draw / erase action.
	reg [23:0] wait_counter;       // The counter for gap between each move of the snake.
	reg [19:0] restart_counter;    // The counter for clear screen action.
	reg collide;
	reg eat;
	reg [6:0] length;
	reg enter_tunnel1;
	reg enter_tunnel2;
	reg invalid_food;	
	reg [7:0] r_x;
	reg [6:0] r_y;

	
	wire [5:0] random_x;
	wire [4:0] random_y;
	wire [7:0] random_food_x;
	wire [6:0] random_food_y;

	random_x_counter rx(
		.CLOCK_50(CLOCK_50),
		.resetn(reset_n),
		.random_x(random_x)
	);
	
	random_y_counter ry(
		.CLOCK_50(CLOCK_50),
		.resetn(reset_n),
		.random_y(random_y)
	);

	integer index; // Reserved for "for loops" below.
	
	localparam  INITIALIZE =  20'd0,
					INIT_HEAD = 5'd1,
					INIT_BODY_1 = 5'd2,
					INIT_BODY_2 = 5'd3,
					INIT_TAIL = 5'd4,
					INIT_FOOD = 5'd5,
					HOLD = 5'd6,
					ERASE_TAIL = 5'd7,
					SHIFT_ARRAY = 5'd8,
					UPDATE_POSITION1 = 5'd9,
					UPDATE_POSITION2 = 5'd10,
					CHECK = 5'd11,
					DRAW_NEW1 = 5'd12,
					DRAW_NEW2 = 5'd13,
					DRAW_NEW3 = 5'd14,
					DRAW_NEW4 = 5'd15,
					UPDATE_HEAD = 5'd16,
					UPDATE_FOOD = 5'd17,
					DELAY = 5'd18,
					RESTART = 5'd19,
					OBSTACLE1 = 5'd20,
					OBSTACLE2 = 5'd21,
					TUNNEL_ENTRANCE = 5'd22,
					TUNNEL_EXIT = 5'd23;
	
	always @ (posedge CLOCK_50, negedge reset_n)
	begin
		if (!reset_n) 
			begin
				current_state <= INITIALIZE;
				position[0] <= {8'd60, 7'd60};  // The snake's head.
				position[1] <= {8'd56, 7'd60};  
				position[2] <= {8'd52, 7'd60};
				position[3] <= {8'd48, 7'd60};  // The snake's tail.
				
				for (index = 4; index < 128; index = index +1) 
					begin
						position[index] <= {8'd48, 7'd60};
					end

				food <= {8'd80, 7'd40};
				collide = 0;
				eat = 0;
				length <= 7'd4;
				score = 7'd0;
				direction <= 2'b11;
				current_state <= RESTART;
				draw_erase_counter = 5'b0;
				wait_counter = 24'b0;
				restart_counter <= 20'd0;
				plot = 1'b1;
				restart_game = 1'b1;
			end
		else
			begin: state_table // Finite State Machine
				current_state <= next_state;
				begin: states
					case (current_state)
						INITIALIZE: 
							begin
								next_state = INIT_HEAD;
								wait_counter <= 24'd0;
								restart_counter <= 20'd0;
								length <= 7'd4;
							end
						INIT_HEAD: 
							next_state = (draw_erase_counter ==  20'd21) ? INIT_BODY_1 : INIT_HEAD;
						INIT_BODY_1: 
							next_state = (draw_erase_counter ==  20'd21) ? INIT_BODY_2 : INIT_BODY_1;
						INIT_BODY_2: 
							next_state = (draw_erase_counter ==  20'd21) ? INIT_TAIL : INIT_BODY_2;
						INIT_TAIL: 
							next_state = (draw_erase_counter ==  20'd21) ? INIT_FOOD : INIT_TAIL;
						INIT_FOOD: 
							next_state = (draw_erase_counter ==  20'd21) ? OBSTACLE1 : INIT_FOOD;
						OBSTACLE1: 
							next_state = (draw_erase_counter ==  20'd21) ? OBSTACLE2 : OBSTACLE1;
						OBSTACLE2: 
							next_state = (draw_erase_counter ==  20'd21) ? TUNNEL_ENTRANCE : OBSTACLE2;
						TUNNEL_ENTRANCE: 
							next_state = (draw_erase_counter ==  20'd21) ? TUNNEL_EXIT : TUNNEL_ENTRANCE;
						TUNNEL_EXIT: 
							next_state = (draw_erase_counter ==  20'd21) ? HOLD : TUNNEL_EXIT;
						HOLD: 
							next_state = (|{up, down, left, right}) ? ERASE_TAIL : HOLD;
						ERASE_TAIL: 
							next_state = (draw_erase_counter ==  20'd21) ? SHIFT_ARRAY : ERASE_TAIL;
						SHIFT_ARRAY: 
							next_state = UPDATE_POSITION1;
						UPDATE_POSITION1: 
							next_state = UPDATE_POSITION2;
						UPDATE_POSITION2: 
							next_state = CHECK;
						CHECK: if (collide)
									next_state = RESTART;
								 else if (eat)
									next_state = DRAW_NEW1;
								 else 
									next_state = UPDATE_HEAD;
						DRAW_NEW1: 
							next_state = (draw_erase_counter ==  20'd21) ? DRAW_NEW2 : DRAW_NEW1;
						DRAW_NEW2: 
							next_state = (draw_erase_counter ==  20'd21) ? DRAW_NEW3 : DRAW_NEW2;
						DRAW_NEW3: 
							next_state = (draw_erase_counter ==  20'd21) ? DRAW_NEW4 : DRAW_NEW3;
						DRAW_NEW4: 
							next_state = (draw_erase_counter ==  20'd21) ? UPDATE_HEAD : DRAW_NEW4;
						UPDATE_HEAD: 
							next_state = (draw_erase_counter ==  20'd21) ? UPDATE_FOOD : UPDATE_HEAD;
						UPDATE_FOOD: 
							next_state = (draw_erase_counter ==  20'd21) ? DELAY : UPDATE_FOOD;
						DELAY: 
							begin
								next_state = (wait_counter == rate) ? ERASE_TAIL : DELAY;
								if (wait_counter == rate) 
									wait_counter <= 24'd0;
								else
									wait_counter <= wait_counter + 1'd1;
							end
						RESTART: 
							begin
								next_state = (restart_counter == 20'd833334) ? INITIALIZE: restart_game;
								if (restart_counter == 20'd833334)
									restart_counter <= 20'd0;
								else
									restart_counter <= restart_counter + 1'd1;
							end
						default: 
							next_state = RESTART;
					endcase
				end
				
				begin: orientation // Determines the direction in which the snack will move.
					case ({up, down, left, right})
						4'b1000: direction <= (direction != 2'b01) ? 2'b00 : direction;
						4'b0100: direction <= (direction != 2'b00) ? 2'b01 : direction;
						4'b0010: direction <= (direction != 2'b11) ? 2'b10 : direction;
						4'b0001: direction <= (direction != 2'b10) ? 2'b11 : direction;
						default: direction <= direction; // Disallow pressing two keys at a time.
					endcase
				end
				
				begin: update_positions
					case (current_state)
						UPDATE_POSITION1:
							begin
								case (direction)
									2'b00: 
										if (position[1][6:0] == 7'd0)
											collide = 1'b1;
										else if (position[1] == {8'd120, 7'd24})
											position[0] <= {8'd20, 7'd96};
										else if (position[1] == {8'd20, 7'd104})
											position[0] <= {8'd120, 7'd16};
										else
											position[0] <= {position[1][14:7], position[1][6:0] - 7'd4};
									2'b01:
										if (position[1][6:0] == 7'd116)
											collide = 1;
										else if (position[1] == {8'd120, 7'd16})
											position[0] <= {8'd20, 7'd104};
										else if (position[1] == {8'd20, 7'd96})
											position[0] <= {8'd120, 7'd24};
										else
											position[0] <= {position[1][14:7], position[1][6:0] + 7'd4};
									2'b10:
										if (position[1][14:7] == 8'd0)
											collide = 1;
										else if (position[1] == {8'd124, 7'd20})
											position[0] <= {8'd16, 7'd100};
										else if (position[1] == {8'd24, 7'd100})
											position[0] <= {8'd116, 7'd20};
										else
											position[0] <= {position[1][14:7] - 8'd4, position[1][6:0]};
									2'b11: 
										if (position[1][14:7] == 8'd156)
											collide = 1;
										else if (position[1] == {8'd116, 7'd20})
											position[0] <= {8'd24, 7'd100};
										else if (position[1] == {8'd16, 7'd100})
											position[0] <= {8'd124, 7'd20};
										else
											position[0] <= {position[1][14:7] + 8'd4, position[1][6:0]};
								endcase
							end
						UPDATE_POSITION2:
							begin
								for (index = 1; index < length; index = index + 1) 
									begin
										if (position[index] == position[0])
											collide = 1;
									end
								if (position[0] == {8'd20, 7'd20} || position[0] == {8'd100, 7'd100})
									collide = 1;
								if (position[0] == food) 
									begin
										eat = 1;
										score <= score + 8'd1;
										length <= length + 7'd4;
										food <= {random_food_x, random_food_y};
									end
							end
						SHIFT_ARRAY: 
							begin
								for (index = 0; index < 126; index = index + 1) 
									begin
										position[index + 1] <= position[index];
									end
							end
						RESTART: 
							begin
								position[0] <= {8'd60, 7'd60};
								position[1] <= {8'd56, 7'd60};
								position[2] <= {8'd52, 7'd60};
								position[3] <= {8'd48, 7'd60};
								for (index = 4; index < 128; index = index +1) 
									begin
										position[index] <= {8'd48, 7'd60};
									end
								food <= {8'd80, 7'd40};
								collide = 0;
								eat = 0;
								length <= 7'd4;
								score <= 7'd0;
								direction <= 2'b11;
							end
					endcase
				end
				
				begin: output_signals // Determine the output signals (set them to high / low).
					case (current_state)
						INITIALIZE: 
							begin
								load_x = 1'b0;
								load_y = 1'b0;
								erase = 1'b0;
								draw = 1'b0;
								plot = 1'b0;
								restart_game = 1'b0;
								colour <= 3'b010;				
							end	
						INIT_HEAD: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[0][14:7];
								y_count <= position[0][6:0];
								colour <= 3'b010;
							end							
						INIT_BODY_1: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[1][14:7];
								y_count <= position[1][6:0];
								colour <= 3'b010;
							end
						INIT_BODY_2: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								colour <= 3'b010;
								x_count <= position[2][14:7];
								y_count <= position[2][6:0];
							end							
						INIT_TAIL: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[3][14:7];
								y_count <= position[3][6:0];
								colour <= 3'b010;
							end
						INIT_FOOD: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= food[14:7];
								y_count <= food[6:0];
								colour <= 3'b110;
							end
						OBSTACLE1: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= 8'd20;
								y_count <= 7'd20;
								colour <= 3'b011;
							end
						OBSTACLE2: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= 8'd100;
								y_count <= 7'd100;
								colour <= 3'b011;
							end
						TUNNEL_ENTRANCE: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= 8'd120;
								y_count <= 7'd20;
								colour <= 3'b101;
							end
						TUNNEL_EXIT: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= 8'd20;
								y_count <= 7'd100;
								colour <= 3'b101;
							end
						ERASE_TAIL: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								draw = 1'b0;
								erase = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[length - 7'd1][14:7];
								y_count <= position[length - 7'd1][6:0];
							end
						DRAW_NEW1: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[length - 7'd4][14:7];
								y_count <= position[length - 7'd4][6:0];
								colour <= 3'b010;
							end
						DRAW_NEW2: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[length - 7'd3][14:7];
								y_count <= position[length - 7'd3][6:0];
								colour <= 3'b010;
							end
						DRAW_NEW3: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[length - 7'd2][14:7];
								y_count <= position[length - 7'd2][6:0];
								colour <= 3'b010;
							end
						DRAW_NEW4: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[length - 7'd1][14:7];
								y_count <= position[length - 7'd1][6:0];
								colour <= 3'b010;
							end
						UPDATE_HEAD: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= position[0][14:7];
								y_count <= position[0][6:0];
								colour <= 3'b010;
							end
						UPDATE_FOOD: 
							begin
								load_x = 1'b1;
								load_y = 1'b1;
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b0;
								x_count <= food[14:7];
								y_count <= food[6:0];
								colour <= 3'b110;
							end
						RESTART: 
							begin
								erase = 1'b0;
								draw = 1'b1;
								plot = 1'b1;
								restart_game = 1'b1;
								colour <= 3'b000;
							end
					endcase
				end	
				
				begin: counters
					if (current_state == INITIALIZE)
						draw_erase_counter <=  20'd0;
					else if (current_state != INITIALIZE && current_state != HOLD && current_state != UPDATE_POSITION1 && 
								current_state != DELAY && current_state != SHIFT_ARRAY && current_state != UPDATE_POSITION2 && 
								current_state != CHECK)
						begin
							if (draw_erase_counter ==  20'd21)
								draw_erase_counter <=  20'd0;
							else
								draw_erase_counter <= draw_erase_counter + 1'd1;
						end
				end
				
				begin: random_logic
					invalid_food = 1'b0;
					for (index = 1'b0; index < length; index = index + 1'b1) 
						begin
							if (position[index] == {random_x,2'b00, random_y,2'b00})
								invalid_food = (1'b1 || invalid_food);
							else
								invalid_food = (1'b0 || invalid_food);
						end
					if (({random_x,2'b00, random_y,2'b00} == {7'd20,6'd20}) ||
						 ({random_x,2'b00, random_y,2'b00} == {7'd100,6'd100}) ||
						 ({random_x,2'b00, random_y,2'b00} == {7'd120,6'd20}) ||
						 ({random_x,2'b00, random_y,2'b00} == {7'd20,6'd100}))
						  invalid_food = (1'b1 || invalid_food);
					else
						  invalid_food = (1'b0 || invalid_food);
										 if (!invalid_food)
					begin
						r_x <= {random_x,2'b00};
						r_y <= {random_x,2'b00};
					end
				end
			end
	end
	
	assign random_food_x = r_x;
	assign random_food_y = r_y;

endmodule

module random_x_counter(CLOCK_50, resetn, random_x);
	input CLOCK_50;
	input resetn;
	output [5:0] random_x;
	reg [5:0] count;
	initial begin
		count = 6'd0;
		end
	always@(posedge CLOCK_50)
		begin
		if (!resetn)
			count <= 6'd0;
		else 
			begin
				if (count == 6'd39)
					count <= 6'd0;
			else
				count <= count + 1'd1;
			end
		end
	assign random_x = count;
endmodule

module random_y_counter(CLOCK_50, resetn, random_y);
	input CLOCK_50;
	input resetn;
	output [4:0] random_y ;
	reg [4:0] count;
	initial begin
		count = 5'd0;
		end
	always@(posedge CLOCK_50)
		begin 
		if (!resetn)
			count <= 5'd0;
		else
			begin
				if (count == 5'd29)
					count <= 5'd0;
				else
					count <= count + 1'd1;
			end
		end
	assign random_y = count;
endmodule
