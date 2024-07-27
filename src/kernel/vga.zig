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

const font = @import("font.zig");
const limine = @import("limine");
const std = @import("std");

const Log = std.log.scoped(.vga);

pub export var framebuffer_request: limine.FramebufferRequest = .{};

const Display = struct {
    framebuffer: *limine.Framebuffer,

    fn init() !Display {
        if (framebuffer_request.response) |framebuffer_response| {
            const fb = framebuffer_response.framebuffers()[0];
            return Display{ .framebuffer = fb };
        } else {
            Log.err("Failed to retrieve a framebuffer response.", .{});
            return error.MissingFramebuffer;
        }
    }

    fn drawPixel(self: Display, x: usize, y: usize, color: u32) void {
        const offset = y * self.framebuffer.pitch + x * 4;
        @as(*u32, @ptrCast(@alignCast(self.framebuffer.address + offset))).* = color;
    }

    fn drawCharacter(self: Display, face: font.Face, character: u8, x: usize, y: usize, fg: u32, bg: u32) void {
        const width: usize = face.getWidth();
        const height: usize = face.getHeight();

        const position: usize = character * height;
        const glyph: []const u8 = face.data[position..];

        const masks: [8]u8 = .{ 128, 64, 32, 16, 8, 4, 2, 1 };

        for (0..height) |cy| {
            for (0..width) |cx| {
                const color = if (glyph[cy] & masks[cx] == 0) bg else fg;
                self.drawPixel(cx + x, cy + y - 12, color);
            }
        }
    }
};

fn write(context: Context, bytes: []const u8) WriteError!usize {
    const face = if (context.bold) try font.Face.init("./usr/share/fonts/ter-i16b.psf") else try font.Face.init("./usr/share/fonts/ter-i16n.psf");
    const width = face.getWidth();
    const height = face.getHeight();

    var x = context.x;
    var y = context.y;

    for (bytes) |byte| {
        switch (byte) {
            '\n' => {
                x = context.x;
                y += height;
            },
            '\r' => {
                x = context.x;
            },
            else => {
                context.display.drawCharacter(face, byte, x, y, context.fg, context.bg);
                x += width;
            },
        }
    }

    return bytes.len;
}

const Context = struct { display: Display, bold: bool, x: usize, y: usize, fg: u32, bg: u32 };
const WriteError = error{FileNotFound};
pub const Writer = std.io.GenericWriter(Context, WriteError, write);

fn printMessage() !void {
    const display = try Display.init();
    const writer = Writer{ .context = .{
        .display = display,
        .bold = true,
        .x = 0,
        .y = 16,
        .fg = 0xFFFF00,
        .bg = 0x000000,
    } };
    try writer.print("Hello, world!", .{});
}

pub fn init() !void {
    try printMessage();
    Log.info("Initialized the VGA subsystem.", .{});
}
