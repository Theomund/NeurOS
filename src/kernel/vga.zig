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

const limine = @import("limine");
const std = @import("std");

const Log = std.log.scoped(.vga);

pub export var framebuffer_request: limine.FramebufferRequest = .{};

pub fn init() void {
    if (framebuffer_request.response) |framebuffer_response| {
        if (framebuffer_response.framebuffer_count < 1) {
            @panic("Failed to retrieve framebuffer.");
        }

        const framebuffer = framebuffer_response.framebuffers()[0];

        for (0..100) |i| {
            const pixel_offset = i * framebuffer.pitch + i * 4;

            @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = 0xFFFFFFFF;
        }

        Log.info("Initialized the VGA subsystem.", .{});
    } else {
        Log.err("Failed to initialize the VGA subsystem.", .{});
    }
}
