// Testbench
module tb;
  parameter WIDTH = 8;
  parameter ADDR_WIDTH = 3;
  
  reg wr_clk = 0, rd_clk = 0, rst = 1, wr_en = 0, rd_en = 0;
  reg [WIDTH-1:0] wr_data = 0;
  wire [WIDTH-1:0] rd_data;
  wire full, empty;
  
  asynch_fifo #(8, WIDTH, ADDR_WIDTH) fifo(
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_data(wr_data),
    .rd_data(rd_data),
    .full(full),
    .empty(empty)
  );
  
  // Clock generators (different frequencies)
  always #5 wr_clk = ~wr_clk;      // 100 MHz
  always #7 rd_clk = ~rd_clk;      // ~71 MHz
  
  // Release reset after 20ns to allow synchronizers to initialize
  initial
    #20 rst = 0;
  
  // Write task
  task write(input [WIDTH-1:0] data);
    @(negedge wr_clk) wr_en = 1; wr_data = data;
    @(negedge wr_clk) wr_en = 0;
  endtask
  
  // Read task
  task read();
    @(negedge rd_clk) rd_en = 1;
    @(negedge rd_clk) rd_en = 0;
  endtask
  
  // Stimulus
  initial
    begin
      #50;  // Wait for reset to propagate and synchronizers to settle
      
      // Write 8 elements
      write(8'hAA);
      write(8'hBB);
      write(8'hCC);
      write(8'hDD);
      write(8'hEE);
      write(8'hFF);
      write(8'h11);
      write(8'h22);
      
      #100;
      
      // Read all 8 elements
      repeat(8)
        read();
      
      #100;
      
      // Concurrent write and read
      fork
        repeat(5) begin
          write($random);
          #30;
        end
        repeat(5) begin
          read();
          #40;
        end
      join
      
      #200 $finish;
    end
  
  // VCD dump
  initial
    begin
      $dumpfile("async_fifo.vcd");
      $dumpvars(0, tb);
    end
  
endmodule
