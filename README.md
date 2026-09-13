# FIFO
# 8-Entry Asynchronous FIFO (First-In-First-Out) Buffer

A synthesizable Verilog implementation of a circular buffer with parameterized depth, 
write/read pointers, and full/empty flag logic.

## Features
- **8-entry dual-pointer architecture**: Write and read pointers track queue state with 4-bit 
  counters to detect wrap-around
- **Full/Empty detection**: Implements MSB-based distinction between full (pointer difference = 8) 
  and empty (pointers equal) conditions
- **Synchronous design**: All pointer updates and reads occur on clock edges
- **Testbench with random stimulus**: Verifies 10 sequential writes followed by 10 reads with 
  waveform capture

## Architecture
- Memory: 8×8-bit register array indexed by pointer LSBs
- Write path: Stores data when `wr_en=1` and FIFO not full
- Read path: Outputs data when `rd_en=1` and FIFO not empty
- Pointers auto-increment; MSB differentiates full from empty wraparound

## Waveform Validation
Captures confirm correct pointer progression, data integrity through read/write cycles, 
and proper flag timing during queue transitions.
