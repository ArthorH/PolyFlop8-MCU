# 💾 PolyFlop8: A Verified 8-bit Microcontroller

[![VHDL](https://img.shields.io/badge/VHDL-Synthesizable-blue?style=flat-square)](https://github.com/ArthorH/PolyFlop8-MCU)
[![Xilinx Vivado](https://img.shields.io/badge/Xilinx-Vivado_2025-red?style=flat-square)](https://www.xilinx.com/)
[![Verification](https://img.shields.io/badge/Verification-ISTQB_Compliant-green?style=flat-square)](https://github.com/ArthorH/PolyFlop8-MCU/tree/main/Documentation/Testability)

> *"A simple CPU design with industrial-grade verification."*

---

## 🎯 Project Overview

<p align="center">
  <img width="100%" alt="PolyFlop8 Architecture" src="https://github.com/user-attachments/assets/9578613b-d656-4fe3-a824-ed92bdf9e1d9" />
</p>

**PolyFlop8** is an **8-bit Harvard Architecture microcontroller** designed for FPGA implementation. While the architecture is intentionally simple (featuring a 2-stage pipeline and an 8-bit bus), the project emphasizes **rigorous verification** using ISTQB standards.

This project serves as a case study in:
* Applying **V-Model verification** to hardware design ([Strategy Overview](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/PolyFlop8_TestCard_ST_Overwiew.pdf)).
* Creating **traceable test requirements** ([Requirements Document](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/PolyFlop8_ISTQB_Test_Bench_requirements.pdf)).

### 📥 Quick Links
* [**Architecture Description**](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Technical%20Reference/PolyFlop8_Block_Description-1.3.pdf) – Detailed block breakdown.
* [**Datasheet**](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Datasheet.pdf) – Electrical and timing specs.

---

## 🔧 Technical Details

| Component | Description |
| :--- | :--- |
| **Architecture** | 8-bit Harvard (separate code/data memory) |
| **Pipeline** | 2-stage (Fetch → Execute) |
| **Memory** | 256B RAM (Async reads, Sync writes) |
| **ISA** | 20+ instructions (Arithmetic, Logic, Branching) |
| **I/O** | Memory-mapped Input/Output |

---

## 🛡️ Verification Approach

The project follows a **hierarchical verification strategy** ([view strategy PDF](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/PolyFlop8_TestCard_ST_Overwiew.pdf)):

1.  **Unit Tests:** Each component (ALU, Register File, etc.) is verified in isolation.
    * *Example:* [Decoder test card](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/TestReports-UnitTest/TC-DEC-001.pdf)
2.  **Subsystem Tests:** Integration of data path and fetch units.
    * *Example:* [Data path test card](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/TestCards-Subystem/PolyFlop8_TestCard_ST_DataPath.pdf)
3.  **System Tests:** Full CPU validation with instruction sequences.
    * *Status:* 🚧 *Under Construction...*

**Key Verification Metrics:**
* **Traceable test cases** linking requirements to results.
* **Bottom-up integration** with coverage-driven testing.

---

## 📂 Project Structure

```text
Root
├── Documentation
│   ├── Architecture Drawings    # Block diagrams & Datapaths
│   ├── Technical Reference      # Block Specs (ALU, RAM) & ISA
│   └── Testability              # ISTQB Verification Artifacts
│       ├── TestCards-Subystem   # Integration Test Plans
│       ├── TestCards-UnitTest   # Unit Requirements (TC-*.pdf)
│       └── TestReports-UnitTest # Execution Results (Evidence of Success)
└── Polyflop8                    # Xilinx Vivado Project Root
    ├── .Xil                     # Vivado build artifacts
    ├── Polyflop8.srcs           # Source Code
    │   └── sources_1
    │       └── new
    │           ├── PolyFlop8        # Synthesizable VHDL (RTL)
    │           └── Unit_test_bench  # Testbenches for Simulation
    └── Polyflop8.xpr            # Main Project File
```

## ⚙️ Key Components

### ALU & Register File
* Supports standard arithmetic and logic operations.
* Comprehensive flag handling (Z, C, N, V, H).
* Verified with 100+ directed tests.

### Control Unit
* Manages the 2-stage pipeline.
* Handles branching and jumps efficiently.
* Verified for all state machine edge cases.

### Memory System
* 256B RAM with asynchronous read / synchronous write.
* Program ROM with jump/branch support.
* Memory-mapped I/O integration.

---

## 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/ArthorH/PolyFlop8-MCU.git](https://github.com/ArthorH/PolyFlop8-MCU.git)

## 📚 Documentation Map

Detailed engineering documentation is available in the `Documentation/` folder.

| Document | Description | Key Insight |
| :--- | :--- | :--- |
| [**Block Specification**](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Technical%20Reference/PolyFlop8_Block_Description-1.3.pdf) | Defines all blocks used in the project. | **The "Blueprint":** Specs for ALU, RAM, etc. |
| [**ISTQB Requirements**](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/PolyFlop8_ISTQB_Test_Bench_requirements.pdf) | The Verification "Contract". | Defines exactly what every instruction (ADD, JMP, ST) must do to pass. |
| [**Test Strategy**](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Testability/PolyFlop8_TestCard_ST_Overwiew.pdf) | Overview of testing hierarchy. | Explains the folder structure and V-Model adaptation. |
| [**ISA Manual**](https://github.com/ArthorH/PolyFlop8-MCU/blob/main/Documentation/Technical%20Reference/PolyFlop8_Instruction_manual.pdf) | Instruction Set Architecture. | The programmer's reference guide. |
| **Test Artifacts** <br> *(located in `Documentation/Testability`)* | Unit Test Reports & Test Plans. | Actual test results showing **PASS** status and coverage for the Control Unit. |

