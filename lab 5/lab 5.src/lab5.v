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
parameter delay = 7000000;
integer delay_count = 0;
reg[0:399] fibo = 0;
reg [4:0] fibo_idx = 0;
reg signed [5:0] cursor = 0;
reg[0:199] fibo_counter = 0;
reg flag;
reg is_reversed = 1;
reg ready = 0;
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

always @(posedge clk) begin
    if (flag) delay_count = delay_count+1;
    if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
    end 
    else if (flag && delay_count==delay && !is_reversed && ready) begin
//        row_A <= "----------------";
//        row_B <= "................";
        row_A = row_B;
        row_B = {"Fibo #",fibo_counter[cursor*8 +: 8]," is ",fibo[cursor*16 +: 16]};
        cursor = cursor + 1;
        if (cursor==25) cursor = 0;
        delay_count = 1;
    end
    else if (flag && delay_count==delay && is_reversed && ready) begin
//        row_A <= "................";
//        row_B <= "----------------";
        row_B = row_A;
        row_A = {"Fibo #",fibo_counter[cursor*8 +: 8]," is ",fibo[cursor*16 +: 16]};
        cursor = cursor - 1;
        if (cursor<0) cursor = 24;
        delay_count = 1;
    end
//  else if (btn_pressed) begin
//    row_A <= "Hello, World!   ";
//    row_B <= "Demo of the LCD.";
//  end
end

always @(posedge clk) begin
    if (~reset_n) begin
        flag = 0;
    end
    else if (btn_pressed) begin
        flag = 1;
    end
end

always @(posedge clk) begin
    if (btn_pressed) begin
        is_reversed = (is_reversed==1) ? 0 : 1;
    end
end

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
            fibo[fibo_idx*16 +: 15] = fibo[(fibo_idx-1)*16 +: 16] + fibo[(fibo_idx-2)*16 +: 16];
            fibo_counter[fibo_idx*8 +: 8] = fibo_idx + 1;
            fibo_idx = fibo_idx+1;
        end
    end
    if (fibo_idx==25) ready = 1;
end

endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    
parameter TIMER = 2000000; /* 20 msec @ 100MHz */

reg [20:0] counter;
reg debounced_btn_state;
reg pressed;

assign btn_output = debounced_btn_state;

always@(posedge clk) begin
  if (btn_input == 0) begin
    counter <= 0;
    pressed <= 0;
  end else begin
    counter <= counter + 1;
    pressed <= (debounced_btn_state == 1)? 1 : 0;
  end
end

always@(posedge clk) begin
  // wait until the button is pressed continuously for 20 msec
  if (counter == TIMER && pressed == 0)
    debounced_btn_state <= 1;
  else
    debounced_btn_state <= (btn_input == 0)? 0 : btn_output;
end

endmodule