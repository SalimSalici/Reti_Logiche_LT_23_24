# Logic Networks Project - A.Y. 2023-2024

Final project for the Logic Networks (Reti Logiche) course for the academic year 2023-2024.

Instructor: Gianluca Palermo

**Grade**: 30/30 with honors

## Project Objective

The project involves designing a hardware module (in VHDL) that interfaces with memory to process a sequence of words. The module's task is to replace missing values (represented by zeros) with the most recent valid value and to track a "credibility" value that decreases over time until the next valid word appears. The credibility value starts at 31 when a valid word is found and decreases with each missing value, stopping at zero.

The complete specification is available [here](https://github.com/...).

The project rules are available [here](https://github.com/...).

## Documentation

The project documentation is available [here](https://github.com/...).

## Tools Used

| Description        | Tool                   |
|--------------------|------------------------|
| Language           | VHDL                   |
| Development Suite  | Xilinx Vivado v.2016.4 |