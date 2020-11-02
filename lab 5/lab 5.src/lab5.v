`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
parameter delay = 70000000; //  7*10^7
integer delay_count = 0;
reg[0:399] fibo = 0; // registers that contain the 25 fibo numbers
reg [4:0] fibo_idx = 0; // idx that helps initializing the register
reg signed [5:0] cursor = 0; // current index pointing to the fibo and fibo_counter registers
reg[0:199] fibo_counter = 0; // counter register

reg [0:16-1] display_counter; // 16-bit register to display the counter value
reg [0:32-1] display_fibo;    // 32-bit register to display the fibonacci number

reg flag; // 1-bit flag to tell if the button has been pressed
reg is_reversed = 1; // 1-bit flag telling if the scrolling should be reversed or not
reg ready = 0; // ready bit to say when the fibonacci numbers are done computing
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

// Display
always @(posedge clk) begin
    if (flag) delay_count = delay_count+1;
    if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
    end 
    else if (flag && delay_count==delay && !is_reversed && ready) begin
        row_A = row_B;
        row_B = {"Fibo #",display_counter," is ",display_fibo};
        cursor = cursor + 1;
        if (cursor==25) cursor = 0;
        delay_count = 1;
    end
    else if (flag && delay_count==delay && is_reversed && ready) begin
        row_B = row_A;
        row_A = {"Fibo #",display_counter," is ",display_fibo};
        cursor = cursor - 1;
        if (cursor<0) cursor = 24;
        delay_count = 1;
    end
end

// Set flag bit
always @(posedge clk) begin
    if (~reset_n)  flag = 0;
    else if (btn_pressed)  flag = 1;
end

// Set is_reversed bit
always @(posedge clk) begin
    if (~reset_n) is_reversed = 1;
    else if (btn_pressed) begin
        is_reversed = (is_reversed==1) ? 0 : 1;
    end
end

// Compute fibonacci numbers
always @(posedge clk) begin
    if (!ready) begin
        if (fibo[16:31]==0) begin
            fibo[0:15] = 16'h0000;
            fibo[16:31] = 16'h0001;
            fibo_counter[0:7] = 8'h01;
            fibo_counter[8:15]= 8'h02;
            fibo_idx = 2;
        end
        else begin
            fibo[fibo_idx*16 +: 16] = fibo[(fibo_idx-1)*16 +: 16] + fibo[(fibo_idx-2)*16 +: 16];
            fibo_counter[fibo_idx*8 +: 8] = 8'h00+fibo_idx + 1;
            fibo_idx = fibo_idx+1;
        end
    end
    if (fibo_idx==25) ready = 1;
end

// convert to ASCII
always @(posedge clk) begin // offsets: 0, 4
    if (fibo_counter[cursor*8+4 +: 4]<=9) begin
        display_counter[0:7] = {4'b0011,fibo_counter[cursor*8 +: 4]};
        display_counter[8:15] = fibo_counter[cursor*8+4 +: 4]+48; 
    end
    else if (fibo_counter[cursor*8+4 +: 4]>=10) begin
        display_counter[0:7] = {4'b0011,fibo_counter[cursor*8 +: 4]};
        display_counter[8:15] = fibo_counter[cursor*8+4 +: 4]+55;
    end
end

always @(posedge clk) begin // offsets : 0, 4, 8, 12
    display_fibo[0:7] = (fibo[cursor*16 +: 4]<=9) ? fibo[cursor*16 +: 4]+48 : fibo[cursor*16 +: 4]+55;
    display_fibo[8:15] = (fibo[cursor*16+4 +: 4]<=9) ? fibo[cursor*16+4 +: 4]+48 : fibo[cursor*16+4 +: 4]+55;
    display_fibo[16:23] = (fibo[cursor*16+8 +: 4]<=9) ? fibo[cursor*16+8 +: 4]+48 : fibo[cursor*16+8 +: 4]+55;
    display_fibo[24:31] = (fibo[cursor*16+12 +: 4]<=9) ? fibo[cursor*16+12 +: 4]+48 : fibo[cursor*16+12 +: 4]+55;
end

endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    
parameter TIMER = 2000000;

reg [20:0] counter;
reg deb;
reg pressed;

assign btn_output = deb;

always@(posedge clk) begin
  if (btn_input == 0) begin
    counter <= 0;
    pressed <= 0;
  end else begin
    counter <= counter + 1;
    pressed <= (deb == 1)? 1 : 0;
  end
end

always@(posedge clk) begin
  if (counter == TIMER && pressed == 0)
    deb <= 1;
  else
    deb <= (btn_input == 0)? 0 : btn_output;
end

endmodule