<!--
  NeurOS - Hobbyist operating system written in Zig.
  Copyright (C) 2024 Theomund

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <https://www.gnu.org/licenses/>.
-->

# ![Project Logo](https://github.com/Theomund/NeurOS/assets/34360334/7b2e911a-429b-4d44-a4bb-131a8037cb97)

![License](https://img.shields.io/github/license/Theomund/NeurOS?style=for-the-badge&logo=gnu&logoColor=white)
![Build](https://img.shields.io/github/actions/workflow/status/Theomund/NeurOS/linux.yml?style=for-the-badge&logo=linux&logoColor=white)
![Version](https://img.shields.io/badge/0.1.0-blue?style=for-the-badge&logo=git&logoColor=white&label=version&labelColor=gray)
![Toolchain](https://img.shields.io/badge/0.13.0-orange?style=for-the-badge&logo=zig&logoColor=white&label=toolchain&labelColor=gray)

> [!WARNING]
> This project is currently in its early development stage. As a result, you
> might find bugs, incomplete features, and breaking changes. Be aware that
> the system is not yet stable for production use. Use it at your own
> discretion, and prepare for potential issues.

# Overview

This project aims to create a lightweight, modular, and extensible operating
system based on the microkernel architecture. The microkernel design minimizes
the kernel's complexity by delegating most tasks to userspace services,
resulting in improved reliability, security, and maintainability.

In addition, this operating system aims to allow a large language model
(LLM) to interact with the system. What this means is that an AI will have the
eventual ability to interact with the user interface.

As its name suggests, this operating system thematically revolves around
[Neuro-sama](https://en.wikipedia.org/wiki/Neuro-sama), an artificial
intelligence streamer created by [vedal987](https://twitter.com/vedal987).
References from the stream and the community will make an appearance.

Lastly, to ensure compatibility with UNIX and its derivatives, this operating
system will try to adhere to the [POSIX](https://en.wikipedia.org/wiki/POSIX)
specification. This will ease the porting of software from those systems.

# Screenshots

![Intro](https://github.com/Theomund/NeurOS/assets/34360334/8e7fdf47-1c0b-4033-b446-222b979f4574)
![VGA](https://github.com/Theomund/NeurOS/assets/34360334/9cf8459a-5108-40a5-b489-5d320d0c79b5)
![Serial](https://github.com/Theomund/NeurOS/assets/34360334/c111aa28-ecd9-496a-89e2-42f401d91854)

# Roadmap

This delineates the general areas of focus for development (this is
not an exhaustive list):

* [x] **Bootstrapping**
    * [x] Bootloader Configuration
    * [x] Initial RAM Disk
* [x] **System Initialization**
    * [x] Global Descriptor Table (GDT)
    * [x] Interrupt Descriptor Table (IDT)
    * [x] Task State Segment (TSS)
* [x] **Memory Management**
    * [x] Physical Memory Manager
    * [x] Virtual Memory Manager
    * [x] Heap Allocator
* [ ] **Interrupt Handling**
    * [x] CPU Exceptions
        * [x] Division Error
        * [x] Debug
        * [x] Non-Maskable Interrupt (NMI)
        * [x] Breakpoint
        * [x] Overflow
        * [x] Bound Range Exceeded
        * [x] Invalid Opcode
        * [x] Device Not Available
        * [x] Double Fault
        * [x] Invalid TSS
        * [x] Segment Not Present
        * [x] Stack Segment Fault
        * [x] General Protection Fault
        * [x] Page Fault
        * [x] x87 Floating Point
        * [x] Alignment Check
        * [x] Machine Check
        * [x] SIMD Floating Point
        * [x] Virtualization
        * [x] Control Protection
        * [x] Hypervisor Injection
        * [x] VMM Communication
        * [x] Security
    * [ ] Hardware Interrupts
        * [x] Timer
        * [x] Keyboard
        * [x] Serial Port
        * [ ] Mouse
* [ ] **Device Drivers**
    * [ ] Disk
        * [ ] IDE
        * [ ] Serial AT Attachment (SATA)
        * [ ] SCSI
        * [ ] NVMe
    * [ ] Interrupt Controller
        * [x] PIC
        * [ ] Advanced Programmable Interrupt Controller (APIC)
    * [x] Display
    * [x] Serial Port
    * [ ] Keyboard
    * [ ] Mouse
    * [ ] Audio
    * [ ] Timer
        * [ ] Programmable Interval Timer (PIT)
    * [ ] Network Interface Card (NIC)
* [ ] **User Mode**
    * [ ] System Calls
    * [x] Executable and Linkable Format (ELF)
* [ ] **Concurrency**
    * [x] Processes
    * [x] Scheduler
    * [ ] Context Switching
* [ ] **Inter-Process Communication (IPC)**
    * [ ] Messages
    * [ ] Transmission
        * [ ] Asynchronous
        * [ ] Synchronous
* [ ] **Filesystems**
    * [x] USTAR
    * [ ] FAT32
    * [ ] Ext2
* [ ] **Networking**
    * [ ] TCP
    * [ ] UDP
    * [ ] Internet Control Message Protocol (ICMP)
* [ ] **User Interfaces**
    * [x] Command Line Interface (CLI)
    * [ ] Text User Interface (TUI)
    * [ ] Graphical User Interface (GUI)
* [ ] **Testing Support**
    * [x] Debugging (GDB/LLDB)
    * [ ] Unit Tests
    * [ ] Integration Tests

# Architecture

```mermaid
graph BT
    classDef node color: #f5f6fa, stroke-width: 0px
    style Application fill: #0097e6
    style Drivers fill: #8c7ae6
    style Hardware fill: #e1b12c
    style Kernel fill: #c23616
    style Servers fill: #44bd32
    style Userspace color: #f5f6fa, fill: #2f3640
    Hardware <==> Kernel
    Kernel <==> Drivers
    subgraph Userspace
        Drivers <==> Servers
        Servers <==> Application
    end
```

# Development

If you're interested in developing the operating system, follow the outlined
steps. Make sure you have the necessary tools and dependencies installed on your
system.

## Cloning

Clone the repository to your local machine by using the following command:

```bash
git clone https://github.com/Theomund/NeurOS.git
```

## Compiling

Run the following command to generate an ISO image:

```bash
zig build
```

This command will start the build process based on the configured settings
and source code.

## Running

To run the compiled operating system in a virtual machine, run this
command:

```bash
zig build run
```

This command will start QEMU and run the operating system.

## Debugging

To debug the operating system, open a terminal and run the following command:

```bash
zig build run -Ddebug=true
```

This will start QEMU with the flags needed to use a debugger such
as GDB.

In another terminal, run the following command:

```bash
zig build debug
```

This starts GDB with the correct symbol file and connection parameters.

## Cleaning

To clean the build artifacts and start fresh, use the following command:

```bash
zig build clean
```

This command removes compiled binaries and temporary files.

# License

![GPL Logo](https://www.gnu.org/graphics/gplv3-with-text-136x68.png)

This project uses the
[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)
(or later).

You can find the detailed terms of the license in the [COPYING](COPYING) file.

# Credits

This project features artwork from the following artists, who reserve all
rights to their work:

* [paccha](https://twitter.com/paccha_7)
