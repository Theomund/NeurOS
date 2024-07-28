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

pub fn init() void {
    interrupts.disable();
    Log.info("Initialized the Global Descriptor Table (GDT) subsystem.", .{});
}
