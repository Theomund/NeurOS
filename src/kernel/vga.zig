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

pub fn init() !void {
    try setupFramebuffer();
    Log.info("Initialized the VGA subsystem.", .{});
}

fn setupFramebuffer() !void {
    if (framebuffer_request.response) |framebuffer_response| {
        const framebuffer = framebuffer_response.framebuffers()[0];
        drawPixel(100, 100, framebuffer.address, framebuffer.pitch, 0xFFFFFF);
    } else {
        Log.err("Failed to retrieve a framebuffer response.", .{});
        return error.MissingFramebuffer;
    }
}

fn drawPixel(x: u32, y: u32, address: [*]u8, pitch: u64, color: u32) void {
    const offset = y * pitch + x * 4;
    @as(*u32, @ptrCast(@alignCast(address + offset))).* = color;
}
