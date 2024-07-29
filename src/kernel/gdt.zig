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

const GlobalDescriptorTable = struct {
    entries: Entry[6],

    fn init() GlobalDescriptorTable {
        const null_access = AccessByte{
            .accessed = 0,
            .read_write = 0,
            .direction_conforming = 0,
            .executable = 0,
            .descriptor_type = 0,
            .privilege_level = 0,
            .present = 0,
        };

        const null_flags = Flags{
            .reserved = 0,
            .long_mode_code = 0,
            .size = 0,
            .granularity = 0,
        };

        const kernel_code_access = AccessByte{
            .accessed = 0,
            .read_write = 1,
            .direction_conforming = 0,
            .executable = 1,
            .descriptor_type = 1,
            .privilege_level = 0,
            .present = 1,
        };

        const kernel_code_flags = Flags{
            .reserved = 0,
            .long_mode_code = 1,
            .size = 0,
            .granularity = 1,
        };

        const kernel_data_access = AccessByte{
            .accessed = 0,
            .read_write = 1,
            .direction_conforming = 0,
            .executable = 0,
            .descriptor_type = 1,
            .privilege_level = 0,
            .present = 1,
        };

        const kernel_data_flags = Flags{
            .reserved = 0,
            .long_mode_code = 0,
            .size = 1,
            .granularity = 1,
        };

        const user_code_access = AccessByte{
            .accessed = 0,
            .read_write = 1,
            .direction_conforming = 0,
            .executable = 1,
            .descriptor_type = 1,
            .privilege_level = 3,
            .present = 1,
        };

        const user_code_flags = Flags{
            .reserved = 0,
            .long_mode_code = 1,
            .size = 0,
            .granularity = 1,
        };

        const user_data_access = AccessByte{
            .accessed = 0,
            .read_write = 1,
            .direction_conforming = 0,
            .executable = 0,
            .descriptor_type = 1,
            .privilege_level = 3,
            .present = 1,
        };

        const user_data_flags = Flags{
            .reserved = 0,
            .long_mode_code = 0,
            .size = 1,
            .granularity = 1,
        };

        const task_state_access = AccessByte{
            .accessed = 1,
            .read_write = 0,
            .direction_conforming = 0,
            .executable = 1,
            .descriptor_type = 0,
            .privilege_level = 0,
            .present = 1,
        };

        const task_state_flags = Flags{
            .reserved = 0,
            .long_mode_code = 0,
            .size = 0,
            .granularity = 0,
        };

        const entries = .{
            createEntry(0, 0, null_access, null_flags),
            createEntry(0, 0xFFFFF, kernel_code_access, kernel_code_flags),
            createEntry(0, 0xFFFFF, kernel_data_access, kernel_data_flags),
            createEntry(0, 0xFFFFF, user_code_access, user_code_flags),
            createEntry(0, 0xFFFFF, user_data_access, user_data_flags),
            createEntry(0, 0xFFFFF, task_state_access, task_state_flags),
        };

        return .{ .entries = entries };
    }

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
};

pub fn init() void {
    interrupts.disable();
    Log.info("Initialized the Global Descriptor Table (GDT) subsystem.", .{});
}
