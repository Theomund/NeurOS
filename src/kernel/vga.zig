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

const Cursor = struct {
    x: usize,
    y: usize,
    bg: u32,
    fg: u32,
};

const Color = enum(u32) {
    black = 0x000000,
    white = 0xFFFFFF,
};

const Display = struct {
    cursor: Cursor,
    framebuffer: *limine.Framebuffer,

    const Writer = std.io.GenericWriter(*Display, error{FileNotFound}, write);

    fn init() !Display {
        if (framebuffer_request.response) |framebuffer_response| {
            const cursor = Cursor{
                .x = 0,
                .y = 12,
                .fg = @intFromEnum(Color.white),
                .bg = @intFromEnum(Color.black),
            };
            const framebuffer = framebuffer_response.framebuffers()[0];
            return Display{ .cursor = cursor, .framebuffer = framebuffer };
        } else {
            Log.err("Failed to retrieve a framebuffer response.", .{});
            return error.MissingFramebuffer;
        }
    }

    fn drawPixel(self: Display, x: usize, y: usize, color: u32) void {
        const offset = y * self.framebuffer.pitch + x * 4;
        @as(*u32, @ptrCast(@alignCast(self.framebuffer.address + offset))).* = color;
    }

    fn drawCharacter(self: Display, face: font.Face, character: u8) void {
        const width: usize = face.getWidth();
        const height: usize = face.getHeight();

        const position: usize = character * height;
        const glyph: []const u8 = face.data[position..];

        const masks: [8]u8 = .{ 128, 64, 32, 16, 8, 4, 2, 1 };

        for (0..height) |cy| {
            for (0..width) |cx| {
                const color = if (glyph[cy] & masks[cx] == 0) self.cursor.bg else self.cursor.fg;
                self.drawPixel(cx + self.cursor.x, cy + self.cursor.y - 12, color);
            }
        }
    }

    fn getCursor(self: Display) Cursor {
        return self.cursor;
    }

    fn setCursor(self: *Display, x: usize, y: usize, fg: u32, bg: u32) void {
        self.cursor = Cursor{ .x = x, .y = y, .fg = fg, .bg = bg };
    }

    fn write(self: *Display, bytes: []const u8) !usize {
        const face = try font.Face.init("./usr/share/fonts/ter-i16n.psf");
        const width = face.getWidth();
        const height = face.getHeight();

        const cursor = self.getCursor();

        var x = cursor.x;
        var y = cursor.y;

        for (bytes) |byte| {
            switch (byte) {
                '\n' => {
                    x = cursor.x;
                    y += height;
                },
                '\r' => {
                    x = cursor.x;
                },
                else => {
                    self.drawCharacter(face, byte);
                    x += width;
                },
            }
            self.setCursor(x, y, cursor.fg, cursor.bg);
        }

        return bytes.len;
    }

    fn writer(self: *Display) Writer {
        return .{ .context = self };
    }
};

pub fn init() !void {
    try printMessage();
    Log.info("Initialized the VGA subsystem.", .{});
}

pub fn printMessage() !void {
    var display = try Display.init();
    const writer = display.writer();
    try writer.print("Hello, world!", .{});
}
