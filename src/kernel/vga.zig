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

const ansi = @import("ansi.zig");
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
    blue = 0x0097E6,
    green = 0x44BD32,
    red = 0xE84118,
    white = 0xF5F6FA,
    yellow = 0xFBC531,
};

const Display = struct {
    cursor: Cursor,
    framebuffer: *limine.Framebuffer,

    const Reader = std.io.GenericReader(*Display, error{}, read);
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

    fn read(self: *Display, buffer: []u8) !usize {
        _ = self;
        _ = buffer;
        return 0;
    }

    fn write(self: *Display, bytes: []const u8) !usize {
        var face = try font.Face.init("./usr/share/fonts/ter-i16n.psf");
        const width = face.getWidth();
        const height = face.getHeight();

        const cursor = self.getCursor();
        var x = cursor.x;
        var y = cursor.y;
        var fg = cursor.fg;

        var i: usize = 0;
        while (i < bytes.len) {
            switch (bytes[i]) {
                '\x1b' => {
                    const slice = bytes[i..];
                    const end = std.mem.indexOf(u8, slice, "m").?;
                    const sequence = slice[0 .. end + 1];

                    if (std.mem.eql(u8, sequence, ansi.blue)) {
                        fg = @intFromEnum(Color.blue);
                    } else if (std.mem.eql(u8, sequence, ansi.bold)) {
                        face = try font.Face.init("./usr/share/fonts/ter-i16b.psf");
                    } else if (std.mem.eql(u8, sequence, ansi.default)) {
                        fg = @intFromEnum(Color.white);
                    } else if (std.mem.eql(u8, sequence, ansi.green)) {
                        fg = @intFromEnum(Color.green);
                    } else if (std.mem.eql(u8, sequence, ansi.normal)) {
                        face = try font.Face.init("./usr/share/fonts/ter-i16n.psf");
                    } else if (std.mem.eql(u8, sequence, ansi.red)) {
                        fg = @intFromEnum(Color.red);
                    } else if (std.mem.eql(u8, sequence, ansi.yellow)) {
                        fg = @intFromEnum(Color.yellow);
                    } else {
                        Log.warn("Encountered an unknown ANSI escape sequence.", .{});
                    }

                    i += end;
                },
                '\n' => {
                    x = cursor.x;
                    y += height;
                },
                '\r' => {
                    x = cursor.x;
                },
                else => {
                    self.drawCharacter(face, bytes[i]);
                    x += width;
                },
            }
            self.setCursor(x, y, fg, cursor.bg);
            i += 1;
        }

        return bytes.len;
    }

    pub fn reader(self: *Display) Reader {
        return .{ .context = self };
    }

    pub fn writer(self: *Display) Writer {
        return .{ .context = self };
    }
};

pub var display: Display = undefined;

pub fn init() !void {
    try setupDisplay();
    Log.info("Initialized the VGA subsystem.", .{});
}

fn setupDisplay() !void {
    display = try Display.init();
}
