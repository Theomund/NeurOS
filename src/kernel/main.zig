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

const gdt = @import("gdt.zig");
const initrd = @import("initrd.zig");
const interrupts = @import("interrupts.zig");
const limine = @import("limine");
const logger = @import("logger.zig");
const memory = @import("memory.zig");
const serial = @import("serial.zig");
const shell = @import("shell.zig");
const smp = @import("smp.zig");
const std = @import("std");
const vga = @import("vga.zig");

pub const Log = std.log.scoped(.kernel);

pub const std_options: std.Options = .{ .log_level = .debug, .logFn = logger.log };

pub export var base_revision: limine.BaseRevision = .{ .revision = 2 };

inline fn done() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

export fn _start() callconv(.C) noreturn {
    if (!base_revision.is_supported()) {
        @panic("Failed to use base revision.");
    }

    gdt.init();
    interrupts.init();
    serial.init();

    vga.init() catch |err| {
        Log.err("Failed to initialize the VGA subsystem [{}].", .{err});
    };

    memory.init() catch |err| {
        Log.err("Failed to initialize the memory subsystem [{}].", .{err});
    };

    smp.init() catch |err| {
        Log.err("Failed to initialize the SMP subsystem [{}].", .{err});
    };

    initrd.init() catch |err| {
        Log.err("Failed to initialize the initial RAM disk (initrd) subsystem [{}].", .{err});
    };

    Log.info("The operating system has been successfully initialized.", .{});

    shell.init() catch |err| {
        Log.err("Failed to initialize the shell subsystem [{}].", .{err});
    };

    done();
}
