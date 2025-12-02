## FPGA Repository (Work in Progress)

This repository is under continuous development. As I deepen my studies in **SystemVerilog, Verilog, VHDL, and MicroBlaze**, new modules, revisions, and improvements are regularly added.
Rather than a static collection of examples, this space serves as a **structured learning lab**, where real implementations evolve alongside my growing proficiency in digital systems and reconfigurable architectures.

Most of the experiments and modules are developed and tested on an **Artix-7 FPGA**, specifically the **XC7A50T** device available on the **Colorlight i9+ board**.

## Purpose

* Consolidate essential HDL concepts
* Build reusable functional blocks
* Experiment with digital architectures and communication protocols
* Maintain a clear, organized record of technical progress
* Develop a solid portfolio for future work involving FPGAs, embedded imaging, and digital systems

## What’s Already Implemented

### 🔹 Fundamentals & State Machines

* FSM examples (Mealy/Moore)
* Combinational and sequential modeling exercises
* Demonstrations of good design practices: resets, partitioning, clocking, and testbench structure

### 🔹 Communication Protocols

* **UART** (Verilog & VHDL): transmitter, receiver, baud generator
* **SPI** (Verilog): master controller
* **I²C** (Verilog): start/stop conditions, ACK/NACK handling, timing logic

### 🔹 Display & Image Processing

* Image rendering in VHDL
* Hardware pipelines for filtering: blur, edge detection, and other operators
* Experiments with spatial parallelism and continuous pixel streaming

### 🔹 MicroBlaze & Embedded Systems

* Integration projects using the MicroBlaze soft-core
* Communication with dedicated peripherals
* Early-stage hybrid HW/SW structures under exploration
