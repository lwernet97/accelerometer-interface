# Accelerometer Data Retrieval System (FPGA, VHDL)

## Overview
Designed and implemented a digital system on an Artix-7 FPGA to interface with an ADXL362 accelerometer using SPI communication. The system retrieves, processes, and displays real-time motion data.

## Features
- SPI communication with ADXL362 accelerometer
- FSM-based control unit for register configuration and data acquisition
- Real-time data retrieval of X, Y, Z, and temperature measurements
- Data display on LEDs (16-bit) and 7-segment displays (8-bit)

## Hardware
- FPGA: Xilinx Artix-7 (CSG324, A100T)
- Accelerometer: ADXL362 (3-axis MEMS sensor)

## Tools Used
- Vivado
- VHDL

## Implementation
- Implemented SPI controller to read/write accelerometer registers  
- Designed FSM to:
  - Configure device registers (0x1F, 0x2D)
  - Perform cyclic reads of 12 data registers  
- Used register arrays to store sensor data  
- Integrated datapath with display modules (LEDs + 7-segment serializer)
- The system reads 12 accelerometer registers and organizes them into:
  - 16-bit measurements (X, Y, Z, Temperature)
  - 8-bit values for display

## Testing & Validation
- Simulated SPI communication using testbench (MISO forced to logic ‘1’)
- Verified FSM behavior across states (S1–S8) and correct sequencing of read/write operations  
- Observed correct SPI signals (MOSI, MISO, SCLK, CS) during transactions  
- Validated output data on LEDs and 7-segment displays  
- Verified correct register reads and FSM transitions  
- Confirmed expected output behavior and data formatting :contentReference[oaicite:1]{index=1}  

## Challenges
- Debugging SPI timing and synchronization issues  
- Managing FSM transitions for sequential register reads  
- Handling simulation constraints vs real hardware timing  

## What I Learned
- FPGA-based SPI communication  
- Designing control units using FSM (ASM charts)  
- Hardware/software integration and debugging  
- Real-time data acquisition systems
