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

const interrupts = @import("interrupts.zig");
const std = @import("std");

const Log = std.log.scoped(.gdt);

const AccessByte = packed struct {
    accessed: u1,
    read_write: u1,
    direction_conforming: u1,
    executable: u1,
    descriptor_type: u1,
    privilege_level: u2,
    present: u1,
};

const Flags = packed struct {
    reserved: u1,
    long_mode_code: u1,
    size: u1,
    granularity: u1,
};

const Entry = packed struct {
    limit_low: u16,
    base_low: u24,
    access: AccessByte,
    limit_high: u4,
    flags: Flags,
    base_high: u8,
};

const Offset = enum(u16) {
    null_descriptor = 0x00,
    kernel_code = 0x08,
    kernel_data = 0x10,
    user_code = 0x18,
    user_data = 0x20,
    tss = 0x28,
};

fn createEntry(base: u32, limit: u20, access: AccessByte, flags: Flags) Entry {
    return .{
        .limit_low = @truncate(limit),
        .base_low = @truncate(base),
        .access = access,
        .limit_high = @truncate(limit >> 16),
        .flags = flags,
        .base_high = @truncate(base >> 24),
    };
}

pub fn init() void {
    interrupts.disable();
    Log.info("Initialized the Global Descriptor Table (GDT) subsystem.", .{});
}
