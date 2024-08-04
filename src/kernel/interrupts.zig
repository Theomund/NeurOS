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
