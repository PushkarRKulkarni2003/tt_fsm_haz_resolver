<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->
## Credits 
We gratefully acknowledge the Centre of Excellence (CoE) in Integrated Circuits and Systems (ICAS) and Department of Electronics and Communication (ECE) for providing the necessary resources and guidance. Special thanks to Dr. H V Ravish Aradhya (HOD-ECE), Dr. K S Geetha (Vice Principal) and Dr. K N Subramanya (Principal) for their constant support and encouragement to carry out this Tiny Tapeout SKY25a submission.

## How it works

The FSM continuously observes the pipeline to detect hazards that could disrupt correct instruction execution. It has six states: Normal (Nor) for hazard-free execution, Control (Con) for handling branches, Flush for clearing mispredicted instructions, Data (Dat) when a read-after-write conflict is detected, StaN for multi-cycle stalls caused by unresolved data hazards, and StaSin for single-cycle stalls due to structural conflicts.

**Control Hazard** occur when a branch instruction enters the pipeline, the FSM transitions from Nor to Con and freezes the program counter to prevent new instructions from being fetched. If the branch resolves correctly, the FSM returns to Nor. If the prediction is wrong, the FSM goes into Flush for one cycle, asserting the flush signal to clear wrong-path instructions before resuming execution.

**Data hazards** are detected whenever one instruction needs data that has not yet been written back by a previous instruction. If forwarding hardware is available, the FSM allows immediate continuation by staying in Nor. If forwarding is unavailable, the FSM first enters Dat and then moves to StaN, where it holds the pipeline in a multi-cycle stall until the data dependency is cleared.

**Structural hazards** occur when two instructions require the same hardware resource at the same time, for example, a memory access and an ALU operation sharing a single data bus. In this case, the FSM transitions into StaSin, freezing the program counter for one cycle or until the conflict is resolved.

Outputs are generated based on the current state. pc_freeze is asserted during stalls and branch waits to stop the fetch stage. do_flush is asserted for one cycle when a mispredicted branch is detected to clear invalid instructions. resolved is high only during Nor, indicating hazard-free execution. Reset is synchronous and active-low; when asserted, the FSM always returns to Nor, ensuring safe startup.

## How to test

You can verify the FSM behavior both in simulation and on hardware (TinyTapeout).
1. Simulation
  •	Run the provided testbench.	It applies various hazard scenarios: control hazards, mispredicts, data hazards with/without forwarding, structural hazards, and overlapping hazards. At every clock edge, the testbench prints:
  o	Input hazard flags (ctrl, data, str, branch, crct, fwrd)
  o	FSM outputs (pc_freeze, do_flush, resolved)
  o	FSM current state (state_out) for debugging.

->	Example test sequences:
  o	ctrl=1, branch=1, crct=1 → FSM handles control hazard and returns to Nor.
  o	ctrl=1, branch=1, crct=0 → FSM issues flush (do_flush=1).
  o	data=1, fwrd=1 → Data hazard detected but resolved via forwarding, no stall.
  o	data=1, fwrd=0 → FSM stalls (StaN) until data clears.
  o	str=1 → FSM performs single-cycle stall (StaSin).

Observe state transitions and control outputs.
2. Hardware (TinyTapeout/FPGA)
•	Map hazard inputs to ui_in bits (e.g., ui_in[0]=ctrl, ui_in[1]=data, etc.).
•	Map FSM outputs to uo_out bits (uo_out[0]=pc_freeze, uo_out[1]=do_flush, uo_out[2]=resolved, uo_out[5:3]=state_out).
•	Provide clock (clk) and reset (rst_n).
•	On TinyTapeout, you can toggle hazard inputs via the web interface or an external driver and watch outputs on LEDs/logic analyzer.
• Implement the same on FPGA by generating the bitstream and dumping the code onto the FPGA Board and manually give inputs to verify the outputs.

## External hardware

This project does not require any external hardware beyond the TinyTapeout digital harness.
Optional for demonstration:
•	LEDs → show FSM state or outputs in real time.
•	Logic analyzer → observe hazard flags and control signals.
•	FPGA board → emulate pipeline signals and drive the FSM before tapeout.

