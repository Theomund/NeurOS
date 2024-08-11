// NeurOS - Hobbyist operating system written in Zig.
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

const std = @import("std");

const Log = std.log.scoped(.interrupts);

const Entry = packed struct {
    offset_low: u16,
    selector: u16,
    ist: u8,
    type_attributes: u8,
    offset_middle: u16,
    offset_high: u32,
    zero: u32,
};

const InterruptDescriptorTable = struct {
    entries: [256]Entry,

    fn init() void {}

    fn createEntry(offset: u64, selector: u16, ist: u8, type_attributes: u8) Entry {
        return .{
            .offset_low = @truncate(offset),
            .selector = selector,
            .ist = ist,
            .type_attributes = type_attributes,
            .offset_middle = @truncate(offset << 16),
            .offset_high = @truncate(offset << 32),
            .zero = 0,
        };
    }
};

const InterruptHandler = fn () callconv(.Interrupt) void;

fn divideError() callconv(.Interrupt) void {
    Log.err("Division error was thrown.", .{});
}

fn debug() callconv(.Interrupt) void {
    Log.debug("Debug excepton was thrown.", .{});
}

fn nmi() callconv(.Interrupt) void {
    Log.err("NMI exception was thrown.", .{});
}

fn breakpoint() callconv(.Interrupt) void {
    Log.warn("Breakpoint exception was thrown.", .{});
}

fn overflow() callconv(.Interrupt) void {
    Log.err("Overflow exception was thrown.", .{});
}

fn boundRange() callconv(.Interrupt) void {
    Log.err("Bound range exception was thrown.", .{});
}

fn invalidOpcode() callconv(.Interrupt) void {
    Log.err("Invalid operation code exception was thrown.", .{});
}

fn deviceNotAvailable() callconv(.Interrupt) void {
    Log.err("Device not available exception was thrown.", .{});
}

fn doubleFault() callconv(.Interrupt) void {
    Log.err("Double fault exception was thrown.", .{});
}

fn invalidTSS() callconv(.Interrupt) void {
    Log.err("Invalid TSS exception was thrown.", .{});
}

fn segmentNotPresent() callconv(.Interrupt) void {
    Log.err("Segment not present exception was thrown.", .{});
}

fn stackSegmentFault() callconv(.Interrupt) void {
    Log.err("Stack segment fault exception was thrown.", .{});
}

fn generalProtectionFault() callconv(.Interrupt) void {
    Log.err("General protection fault exception was thrown.", .{});
}

fn pageFault() callconv(.Interrupt) void {
    Log.err("Page fault exception was thrown.", .{});
}

fn x87FloatingPoint() callconv(.Interrupt) void {
    Log.err("X87 floating point exception was thrown.", .{});
}

fn alignmentCheck() callconv(.Interrupt) void {
    Log.err("Alignment check exception was thrown.", .{});
}

fn machineCheck() callconv(.Interrupt) void {
    Log.err("Machine check exception was thrown.", .{});
}

fn simdFloatingPoint() callconv(.Interrupt) void {
    Log.err("SIMD floating point exception was thrown.", .{});
}

fn virtualization() callconv(.Interrupt) void {
    Log.err("Virtualization exception was thrown.", .{});
}

fn controlProtection() callconv(.Interrupt) void {
    Log.err("Control protection exception was thrown.", .{});
}

fn hypervisorInjection() callconv(.Interrupt) void {
    Log.err("Hypervisor injection exception was thrown.", .{});
}

fn vmmCommunication() callconv(.Interrupt) void {
    Log.err("VMM communication exception was thrown.", .{});
}

fn security() callconv(.Interrupt) void {
    Log.err("Security exception was thrown.", .{});
}

pub fn init() void {
    enable();
    Log.info("Initialized the interrupts subsystem.", .{});
}

pub fn disable() void {
    asm volatile ("cli");
}

fn enable() void {
    asm volatile ("sti");
}
