module fifo(
  input clk, rst, wr_en, rd_en, 
  input [7:0] wr_data,
  output reg [7:0] rd_data,
  output reg full, empty);
  
  int i = 0;
  reg [3:0] wr_ptr = 0, rd_ptr; //wr_addr => wr_ptr, wr_ctr => wr_ptr
  reg [7:0] mem[7:0]; //memory

  
  //1. RST
  //   clk, rst
  always @(posedge clk)
    begin
      if (rst == 1) begin
        for(i=0; i<=7; i=i+1)
          mem[i] = 0;
        wr_ptr = 0;
        rd_ptr = 0;
      end
    end
  
  //2. Write (send => put => push)
  //   clk, wr_en, wr_ptr, wr_data
  always @(posedge clk)
    begin
      if (wr_en == 1 && full != 1)
        begin
          mem[wr_ptr[2:0]] = wr_data;
     	  wr_ptr = wr_ptr + 1;
        end
    end
  
  //3. Read (rcv => get => pop)
  //   clk, rd_en, rd_ptr, rd_data
  always @(posedge clk)
    begin
      if (rd_en == 1 && empty != 1)
        begin
          rd_data = mem[rd_ptr[2:0]];
          rd_ptr = rd_ptr + 1;
        end
    end
  //4. FULL
  //assign full = (wr_ptr[2:0] == rd_ptr[2:0] && wr_ptr[3] != rd_ptr[3]) ? 1:0;
  assign full = ((wr_ptr - rd_ptr) == 8) ? 1:0;
  
  //5. EMPTY
  assign empty = (wr_ptr == rd_ptr) ? 1:0;
  //assign empty = ((wr_ptr - rd_ptr) == 0) ? 1:0;
  //assign empty = (wr_ptr[2:0] == rd_ptr[2:0] && wr_ptr[3] == rd_ptr[3]) ? 1:0;
  //assign empty = (wr_ptr[2:0] == rd_ptr[2:0]) ? 1:0;

endmodule


module tb;
  reg clk = 0, rst, wr_en, rd_en; 
  reg [7:0] wr_data;
  wire [7:0] rd_data;
  wire full, empty;
  
  fifo f0 (clk, rst, wr_en, rd_en, wr_data, rd_data, full, empty);
  
  task reset();
    @(negedge clk) rst = 1;
    @(negedge clk) rst = 0;
  endtask
  
  task write();
    @(negedge clk) wr_en = 1; wr_data = $random;
    @(negedge clk) wr_en = 0;
  endtask
  
  task read();
    @(negedge clk) rd_en = 1;
    @(negedge clk) rd_en = 0;
  endtask
  
  initial
    begin
      reset();
      repeat(10) write();
      repeat(10) read();
    end
   
  always begin
  #5 clk = ~clk;
  end
  initial #1000 $finish;
  
initial begin
  $dumpfile("dump.vcd");
  $dumpvars;
  #10000;
  $finish;
end
endmodule
