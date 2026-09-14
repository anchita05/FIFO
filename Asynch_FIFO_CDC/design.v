// CDC Synchronizer - 2-stage flip-flop chain
module synchronizer #(parameter WIDTH=4)(
  input clk, rst,
  input [WIDTH:0] d_in,
  output reg [WIDTH:0] d_out
);
  reg [WIDTH:0] q1;
  
  always @(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          q1 <= 0;
          d_out <= 0;
        end
      else
        begin
          q1 <= d_in;
          d_out <= q1;
        end
    end
endmodule

// Binary to Gray code converter
module b2g #(parameter WIDTH=3)(
  input [WIDTH:0] binary,
  output [WIDTH:0] gray
);
  assign gray = binary ^ (binary >> 1);
endmodule

// Gray to Binary converter
module g2b #(parameter WIDTH=3)(
  input [WIDTH:0] gray,
  output [WIDTH:0] binary
);
  integer i;
  reg [WIDTH:0] binary_temp;
  
  always @(*)
    begin
      binary_temp[WIDTH] = gray[WIDTH];
      for(i = WIDTH-1; i >= 0; i = i-1)
        binary_temp[i] = binary_temp[i+1] ^ gray[i];
    end
  
  assign binary = binary_temp;
endmodule

// Write Pointer Handler
module wr_ptr_handler #(parameter W=3)(
  input wr_clk, wr_en, wr_rst,
  input [W:0] g_rd_ptr_sync,
  output reg [W:0] b_wr_ptr, g_wr_ptr,
  output reg full
);
  
  wire wr_full;
  wire [W:0] b_wr_ptr_next, g_wr_ptr_next;
  
  // Binary pointer increment
  assign b_wr_ptr_next = b_wr_ptr + (wr_en && !full);
  
  // Gray code of next pointer
  assign g_wr_ptr_next = (b_wr_ptr_next >> 1) ^ b_wr_ptr_next;
  
  // Check full condition: gray pointers match except MSB
  assign wr_full = (g_wr_ptr_next == {~g_rd_ptr_sync[W:W-1], g_rd_ptr_sync[W-2:0]});
  
  // Sequential logic
  always @(posedge wr_clk or posedge wr_rst)
    begin
      if(wr_rst)
        begin
          b_wr_ptr <= 0;
          g_wr_ptr <= 0;
          full <= 0;
        end
      else
        begin
          b_wr_ptr <= b_wr_ptr_next;
          g_wr_ptr <= g_wr_ptr_next;
          full <= wr_full;
        end
    end
endmodule

// Read Pointer Handler
module rd_ptr_handler #(parameter W=3)(
  input rd_clk, rd_en, rd_rst,
  input [W:0] g_wr_ptr_sync,
  output reg [W:0] b_rd_ptr, g_rd_ptr,
  output reg empty
);
  
  wire rd_empty;
  wire [W:0] b_rd_ptr_next, g_rd_ptr_next;
  
  // Binary pointer increment
  assign b_rd_ptr_next = b_rd_ptr + (rd_en && !empty);
  
  // Gray code of next pointer
  assign g_rd_ptr_next = (b_rd_ptr_next >> 1) ^ b_rd_ptr_next;
  
  // Check empty condition: synchronized write ptr equals current read ptr
  assign rd_empty = (g_wr_ptr_sync == g_rd_ptr);
  
  // Sequential logic
  always @(posedge rd_clk or posedge rd_rst)
    begin
      if(rd_rst)
        begin
          b_rd_ptr <= 0;
          g_rd_ptr <= 0;
          empty <= 1;
        end
      else
        begin
          b_rd_ptr <= b_rd_ptr_next;
          g_rd_ptr <= g_rd_ptr_next;
          empty <= rd_empty;
        end
    end
endmodule

// Asynchronous FIFO - 8-element depth, 8-bit width
module asynch_fifo #(parameter DEPTH=8, WIDTH=8, ADDR_WIDTH=3)(
  input wr_clk, rd_clk, rst, wr_en, rd_en,
  input [WIDTH-1:0] wr_data,
  output reg [WIDTH-1:0] rd_data,
  output full, empty
);
  
  initial rd_data = 0;
  
  // Pointers (Gray and Binary)
  wire [ADDR_WIDTH:0] g_wr_ptr, b_wr_ptr;
  wire [ADDR_WIDTH:0] g_rd_ptr, b_rd_ptr;
  wire [ADDR_WIDTH:0] g_rd_ptr_sync, g_wr_ptr_sync;
  
  // Memory
  reg [WIDTH-1:0] mem[DEPTH-1:0];
  
  // Initialize memory to zero
  initial
    begin
      integer i;
      for(i = 0; i < DEPTH; i = i + 1)
        mem[i] = 0;
    end
  
  // Write pointer handler
  wr_ptr_handler #(ADDR_WIDTH) wr_handler(
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .wr_rst(rst),
    .g_rd_ptr_sync(g_rd_ptr_sync),
    .b_wr_ptr(b_wr_ptr),
    .g_wr_ptr(g_wr_ptr),
    .full(full)
  );
  
  // Read pointer handler
  rd_ptr_handler #(ADDR_WIDTH) rd_handler(
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .rd_rst(rst),
    .g_wr_ptr_sync(g_wr_ptr_sync),
    .b_rd_ptr(b_rd_ptr),
    .g_rd_ptr(g_rd_ptr),
    .empty(empty)
  );
  
  // CDC: Synchronize Gray code pointers across clock domains
  synchronizer #(ADDR_WIDTH) rd_sync(
    .clk(wr_clk),
    .rst(rst),
    .d_in(g_rd_ptr),
    .d_out(g_rd_ptr_sync)
  );
  
  synchronizer #(ADDR_WIDTH) wr_sync(
    .clk(rd_clk),
    .rst(rst),
    .d_in(g_wr_ptr),
    .d_out(g_wr_ptr_sync)
  );
  
  // Write logic
  always @(posedge wr_clk)
    begin
      if(wr_en && !full)
        mem[b_wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
    end
  
  // Read logic - always read from current address, latch on rd_en
  always @(posedge rd_clk)
    begin
      rd_data <= mem[b_rd_ptr[ADDR_WIDTH-1:0]];
    end
  
endmodule
