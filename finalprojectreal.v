

module finalprojectreal(GPIO, SW, CLOCK_50, LEDR, KEY, VGA_CLK, VGA_HS, LEDG,
		VGA_VS,
		VGA_BLANK_N,
		VGA_SYNC_N,
		VGA_R,
		VGA_G,
		VGA_B);
	input CLOCK_50;
	output [30:0] GPIO;
	output [17:0] LEDR;
	output VGA_CLK;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	output [7:0] LEDG;
	input [3:0] KEY;
	input [16:0] SW;
	wire [3:0] note;
	wire speak;
	wire noteclock;
	wire [3:0] playnote;
	wire [3:0] displayin;
	wire [3:0] displayout;
	wire [2:0] color;
	wire [7:0] x;
	wire [6:0] y;
	wire [3:0] inputnotefromswitch;
	//reg [3:0] mymem [7:0]; //use this to make screen output?
	//music mymusic(SW[0], noteclock, LEDR[3:0], GPIO[7]);
	//note_synt mynotsynt(CLOCK_50, SW[4:1], noteclock, LEDR[17:10]);choose_music(clock, notein, choose, mode, start, out, blinky, displayin, displayout);
	//timer myt(CLOCK_50, KEY[1], LEDR[6], LEDG[2], SW[14]);
	switchinterp(SW[11:0], inputnotefromswitch);
   choose_music(CLOCK_50, inputnotefromswitch, SW[13:12],SW[16], KEY[0], playnote, LEDR[0], displayin, displayout, LEDR[9:7]);
	screen myscreen(CLOCK_50, displayout, x, y, color, displayin);
	vga_adapter VGA(
			.resetn(1),
			.clock(CLOCK_50),
			.colour(color),
			.x(x),
			.y(y),
			.plot(1),
			/* Signals for the DAC to drive the monitor. */
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
		defparam VGA.BACKGROUND_IMAGE = "background.mif";
	//playrec pl(CLOCK_50, SW[3:0], SW[16:15], KEY[0], playnote, LEDR[0], displayin, displayout);
	note_synt notsynth (CLOCK_50, playnote, noteclock, LEDR[17:10]);
	assign LEDR[5:2] = playnote;
	assign GPIO[5] = noteclock;// freq of noise
	assign GPIO[1] = 1'b0;
	assign GPIO[3] = 1'b1;
	assign LEDR[1] = KEY[0];
endmodule

module choose_music(clock, notein, choose, mode, start, out, blinky, displayin, displayout, disout);
	input clock;
	input [3:0] notein;
	input [1:0] choose;
	input mode;
	input start;
	input [3:0] displayin;
	output reg [3:0] out;
	output reg blinky;
	output reg [3:0] displayout;
	output [2:0] disout;
	reg dis1;
	reg dis2;
	reg dis3;
	wire [3:0] displayout1;
	wire [3:0] displayout2;
	wire [3:0] displayout3;
	wire [3:0] out1;
	wire [3:0] out2;
	wire [3:0] out3;
	wire blinky1;
	wire blinky2;
	wire blinky3;
	
	assign disout[0] = dis1;
	assign disout[1] = dis2;
	assign disout[2] = dis3;
	always @(*)
	begin
	case(choose)
		2'b00: begin out = out1; blinky = blinky1; displayout =displayout1; dis1 = 0; dis2 = 1; dis3 = 1; end
		2'b01: begin out = out2; blinky = blinky2; displayout =displayout2; dis1 = 1; dis2 = 0; dis3 = 1; end
		2'b10: begin out = out3; blinky = blinky3; displayout =displayout3; dis1 = 1; dis2 = 1; dis3 = 0; end
		default: out <= 1'b0;
	endcase
	end
	playrec myrec1(clock, notein, mode, start, out1, blinky1, displayin, displayout1, dis1);
	playrec myrec2(clock, notein, mode, start, out2, blinky2, displayin, displayout2, dis2);
	playrec myrec3(clock, notein, mode, start, out3, blinky3, displayin, displayout3, dis3);
endmodule

module switchinterp(switches, note);
	input [11:0] switches;
	output reg [3:0] note;
	always @(*)
	begin
		if(switches[11])
		begin
			note = 12;
		end
		else if(switches[10])
		begin
			note = 11;
		end
		else if(switches[9])
		begin
			note = 10;
		end
		else if(switches[8])
		begin
			note = 9;
		end
		else if(switches[7])
		begin
			note = 8;
		end
		else if(switches[6])
		begin
			note = 7;
		end
		else if(switches[5])
		begin
			note = 6;
		end
		else if(switches[4])
		begin
			note = 5;
		end
		else if(switches[3])
		begin
			note = 4;
		end
		else if(switches[2])
		begin		
			note = 3;
		end
		else if(switches[1])
		begin
			note = 2;
		end
		else if(switches[0])
		begin
			note = 1;
		end
		else
		begin
			note = 0;
		end
	end
endmodule
module screen(clock, note, x, y, color, noteselector);
	input [3:0] note;
	input clock;
	output  reg [7:0] x;
	output  reg [6:0] y;
	output  reg [2:0] color;
	output  reg [3:0] noteselector;
	reg [20:0] counter;
	reg [7:0]x2;
	reg [6:0]y2;
	always @(posedge clock)
	begin
		counter = counter + 1;
		if (counter == 19200) //19200 to clear screen and 8 to draw our notes
		begin
			counter = 0;
		end
		if (counter < 19200)
		begin
			x = counter % 160;
			y = counter / 160; //FLOOR ???
			if(counter <= 1439)
			begin
				color = 0;
			end
			else if (counter <= 1599)
			begin
				color = 7;
			end
			else if (counter <= 3039)
			begin
				color = 0;
			end
			else if (counter <= 3199)
			begin
				color = 7;
			end
			else if (counter <= 4639)
			begin
				color = 0;
			end
			else if (counter <= 4799)
			begin
				color = 7;
			end
			else if (counter <= 6239)
			begin
				color = 0;
			end
			else if (counter <= 6399)
			begin
				color = 7;
			end
			else if (counter <= 7839)
			begin
				color = 0;
			end
			else if (counter <= 7999)
			begin
				color = 7;
			end
			else if (counter <= 9439)
			begin
				color = 0;
			end
			else if (counter <= 9599)
			begin
				color = 7;
			end
			else if (counter <= 11039)
			begin
				color = 0;
			end
			else if (counter <= 11199)
			begin
				color = 7;
			end
			else if (counter <= 12639)
			begin
				color = 0;
			end
			else if (counter <= 12799)
			begin
				color = 7;
			end
			else if (counter <= 14239)
			begin
				color = 0;
			end
			else if (counter <= 14399)
			begin
				color = 7;
			end
			else if (counter <= 15839)
			begin
				color = 0;
			end
			else if (counter <= 15999)
			begin
				color = 7;
			end
			else if (counter <= 17439)
			begin
				color = 0;
			end
			else if (counter <= 17599)
			begin
				color = 7;
			end
			else if (counter <= 19199)
			begin
				color = 0;
			end
		end
			 noteselector = (x)/20;
			 if((x - 1)%20 == 0)
			 begin
				
				if (y == 122 - (note) * 10)
				begin
					color = 6;
				end
			 end
			 
	end
endmodule 
/*
module notetoscreenvar(note, x, y, color);

endmodule */

module playrec(clock, notein, select, start, note, blinky, displayin, displayout, dis);
	//ON POSEDGE OF START SHOULD DO SOMETHING
	input clock; // 5 mhz
	input [3:0] notein;
	input select;
	input start;
	input dis;
	input [3:0] displayin;
	output [3:0] displayout;
	output [3:0] note;
	output blinky;
//	/output ;
	reg [3:0] mem [7:0];
	reg timerreset;
	reg [3:0] recordertime;
	reg recorderon;
	wire timerout;
	wire playerreset;
	wire recorderreset;
	wire timedone;
	reg [3:0] mymem [7:0];
	storage mystorage(notein, recorderon, timerout, note, timedone, displayin, displayout);
	timer mytimer(clock, start, timerout, timedone, dis);
	//player myplayer(timerout, playerreset, mymem, notein);
	//recorder myrecorder(timerout, recorderreset, note, mymem);
	always @(posedge start)
	begin
		case(select)
			0: begin recorderon <= 1; end //record 
			default:
				begin recorderon <= 0; end// play
		endcase
	end
	assign blinky = timerout;
	/*always @(negedge start)
	begin
			else
		timerreset <= 0;
	end*/

endmodule

module storage(notein, write, clock, noteout, off, displayin, displayout);
	input [3:0] notein;
	input write;
	input clock;
	input [3:0] displayin;
	output reg [3:0] displayout;
	output reg [3:0] noteout;
	input off;
	
	reg [3:0] notes [7:0];
	reg [3:0] curr;
	
	always @(*)
	begin
	 displayout = notes[displayin];
	end
	always @(posedge clock or posedge off)
	begin
		if (off)
		begin
			curr = 0;
			noteout = 0;
		end
		else
		begin
		if(write)
		begin
			notes[curr] = notein;
		end
		noteout = notes[curr];
		curr = curr + 1;
		end
	end
	
endmodule

module timer(clock, reset, q, finished, dis);
	input clock; //clock 50
	input reset;
	input dis;
	output reg q;
	output reg finished;
	reg [4:0]enabled;
	reg [30:0]count;
	always @(posedge clock or negedge reset)
	begin
			if(reset == 0)
			begin
				if(~dis)
				begin
					enabled = 16;
					count = 50_000_000/2;
				end
				else
				begin
					enabled = 0;
					count = 0;
				end
			end
			else
			begin
				if(~dis)
				begin
				if (enabled > 0)
				begin
					finished = 1'b0;
					count = count - 1;
					if (count == 0)
					begin
						count = 50_000_000/2;
						q = ~q;
						enabled = enabled - 1'b1;
					end
				end
				else
				begin
					finished = 1'b1;
				end
				end

		end	
	end
	
endmodule

module note_synt(
    input wire clk,       //source clock 5Mhz
    input wire [3:0]note, //ID of note 
    
                        //output freq grid
                        //basic freq is note A = 440Hz
                        //every next note differs by 2^(-1/12)
                        //C     523,2511306 Hz
                        //C#    554,3652620 Hz
                        //D     587,3295358 Hz
                        //D#    622,2539674 Hz
                        //E     659,2551138 Hz
                        //F     698,4564629 Hz
                        //F#    739,9888454 Hz
                        //G     783,9908720 Hz
                        //G#    830,6093952 Hz
                        //A     880 Hz190840
                        //A#    932,327523  Hz
                        //H     987,7666025 Hz
                        //C     1046,502261 Hz
    output reg note_clock,      //generated note clock
    output reg [7:0]note_leds   //blink LEDs 
);

//divide coeff / ????????
reg [28:0]factor;

//select divide coefficient according to current note being played
always @*
begin
    case(note)
        4'b0000:  begin factor <= 28'd000000; note_leds = 8'b00000000; end 			
        4'b0001:  begin factor <= 28'd190840; note_leds = 8'b00000001; end   //C      1
        4'b0010:  begin factor <= 28'd180386; note_leds = 8'b00000011; end   //C#     2
        4'b0011:  begin factor <= 28'd170262; note_leds = 8'b00000010; end   //D //g  3
        4'b0100:  begin factor <= 28'd160706; note_leds = 8'b00000110; end   //D# //g 4
        4'b0101:  begin factor <= 28'd151686; note_leds = 8'b00000100; end   //E //g  5
        4'b0110:  begin factor <= 28'd143173; note_leds = 8'b00001000; end   //F //g  6
        4'b0111:  begin factor <= 28'd135137; note_leds = 8'b00011000; end   //F# //g 7
        4'b1000:  begin factor <= 28'd127553; note_leds = 8'b00010000; end   //G //g  8
        4'b1001:  begin factor <= 28'd120393; note_leds = 8'b00110000; end   //G# //g 9
        4'b1010:  begin factor <= 28'd113636; note_leds = 8'b00100000; end   //A //g  10
        4'b1011:  begin factor <= 28'd107258; note_leds = 8'b01100000; end   //A# //g 11
        4'b1100:  begin factor <= 28'd101239; note_leds = 8'b01000000; end   //B //g  12
    default: begin factor <= 1;   note_leds = 8'b00000000; end   //nothing / ??????
    endcase
end 

reg eocnt; 
always @(posedge clk)
    eocnt <= (cnt >= factor);
    
reg [28:0]cnt;
always @(posedge clk or posedge eocnt)
begin 
    if(eocnt)
        cnt <= 0;
    else
        cnt <= cnt + 1'b1;
end

//output sound frequency 
always @(posedge eocnt)
    note_clock <= note_clock ^ 1'b1;
 
/*
rate_helper rd(clk, factor, note_clock);
/*
reg eocnt; 
reg [28:0]cnt;
always @(posedge clk)
	begin
		if (cnt == 28'b00000000000000000000000000)
			begin
				cnt <= 28'd50000000;
			end
		else
			begin

				cnt <= cnt - 1'b1;
			end
	end
	
	assign note_clock = (cnt == 28'b0) ? 1 : 0;
	
    */
/*always @(posedge eocnt)
    note_clock <= note_clock ^ 1'b1;*/

endmodule
 
 
 
module rate_helper(clock, selected, q);
	output q;
	reg [28:0] count;
	input [28:0] selected;
	input clock;
	always @(posedge clock)
	begin
		if(count == 28'b00000000000000000000000000)
			count <= 28'd50000000;
		else
			count <= count - 1'b1;
	end
	assign q = (count == 28'b0) ? 1 : 0;
endmodule


