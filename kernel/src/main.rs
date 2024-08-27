// NeurOS - Hobbyist operating system written in Rust.
// Copyright (C) 2024 Theomund
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#![warn(clippy::pedantic)]
#![feature(abi_x86_interrupt)]
#![feature(int_roundings)]
#![no_std]
#![no_main]

extern crate alloc;

mod acpi;
mod ansi;
mod elf;
mod font;
mod gdt;
mod image;
mod initrd;
mod interrupts;
mod intro;
mod keyboard;
mod logger;
mod memory;
mod process;
mod scheduler;
mod serial;
mod shell;
mod smp;
mod syscall;
mod timer;
mod userspace;
mod vga;

use crate::ansi::{BOLD, NORMAL, RED};
use crate::logger::{Level, LOGGER};
use crate::vga::VGA;
use alloc::format;
use core::fmt::Write;
use core::panic::PanicInfo;
use x86_64::instructions;

#[no_mangle]
extern "C" fn kmain() -> ! {
    gdt::initialize();
    memory::initialize();
    interrupts::initialize();
    smp::initialize();
    initrd::initialize();
    scheduler::initialize();
    intro::initialize().expect("Failed to initialize intro.");
    shell::initialize();
    userspace::initialize();
    tick();
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    let mut vga = VGA.lock();
    vga.clear();
    writeln!(vga, "{BOLD}{RED}[KERNEL PANIC]{NORMAL}\n").unwrap();
    fatal!("The kernel has panicked.\n{info}");
    for log in LOGGER.lock().get_logs() {
        writeln!(vga, "{log}").unwrap();
    }
    halt();
}

fn tick() -> ! {
    info!("The operating system has been successfully initialized.");
    instructions::interrupts::enable();
    loop {
        instructions::hlt();
    }
}

fn halt() -> ! {
    instructions::interrupts::disable();
    loop {
        instructions::hlt();
    }
}
