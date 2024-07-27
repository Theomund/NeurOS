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
const serial = @import("serial.zig");
const std = @import("std");

const Context = struct { level: std.log.Level };
const WriteError = error{};
const Writer = std.io.GenericWriter(Context, WriteError, write);

fn write(context: Context, bytes: []const u8) WriteError!usize {
    const writer = serial.COM1.writer();
    const color = switch (context.level) {
        std.log.Level.debug => ansi.green,
        std.log.Level.info => ansi.blue,
        std.log.Level.warn => ansi.yellow,
        std.log.Level.err => ansi.red,
    };
    try writer.print("{s}{s}{s}", .{ color, bytes, ansi.default });
    return bytes.len;
}

pub fn log(comptime message_level: std.log.Level, comptime scope: @TypeOf(.enum_literal), comptime format: []const u8, args: anytype) void {
    const writer = Writer{ .context = Context{ .level = message_level } };
    const message = @tagName(message_level) ++ "(" ++ @tagName(scope) ++ "): " ++ format ++ "\r\n";
    try std.fmt.format(writer, message, args);
}
