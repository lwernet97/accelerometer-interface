# Accelerometer Data Retrieval System (FPGA, VHDL)

## Overview
Designed and implemented a digital system on an Artix-7 FPGA to interface with an ADXL362 accelerometer using SPI communication. The system retrieves, processes, and displays real-time motion data.

## Features
- SPI communication with ADXL362 accelerometer  
- FSM-based control unit for register configuration and data acquisition  
- Real-time retrieval of X, Y, Z, and temperature measurements  
- Data display on LEDs (16-bit) and 7-segment displays (8-bit)

## Hardware
- FPGA: Xilinx Artix-7 (CSG324, A100T)  
- Accelerometer: ADXL362 (3-axis MEMS sensor)

## Tools Used
- Vivado  
- VHDL  

## Implementation
- Integrated SPI controller to read/write accelerometer registers  
- Designed FSM to:
  - Configure device registers (0x1F, 0x2D)  
  - Perform cyclic reads of 12 data registers  
- Developed top-level module to connect control unit and datapath  
- Implemented 8-display serializer for 7-segment output  
- Organized sensor data into high-precision (16-bit) and low-precision (8-bit) formats  

## My Contributions
- Designed top-level FPGA system integrating SPI controller, FSM, and datapath  
- Developed VHDL testbench to simulate SPI transactions and verify system behavior  
- Implemented 8-display serializer for real-time visualization  
- Debugged timing, FSM sequencing, and signal integrity issues  

## Testing & Validation
- Simulated SPI communication using custom testbench (MISO forced high)  
- Verified FSM transitions (S1–S8) and correct sequencing of read/write operations  
- Observed SPI signals (MOSI, MISO, SCLK, CS) during transactions  
- Validated correct data output on LEDs and 7-segment displays  

## Provided Code Notice
Some modules were provided as part of coursework.  
This project focuses on system integration, control logic design, and verification of the complete system.

## Challenges
- Debugging SPI timing and synchronization  
- Managing FSM transitions for sequential register reads  
- Handling simulation vs real hardware timing differences  

## What I Learned
- FPGA-based SPI communication  
- FSM design using ASM methodology  
- Hardware/system-level debugging  
- Real-time data acquisition systems
