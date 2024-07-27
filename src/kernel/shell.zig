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
const initrd = @import("initrd.zig");
const serial = @import("serial.zig");
const std = @import("std");

pub fn init() !void {
    const motd = try initrd.read("./etc/motd");
    const prompt = try parsePrompt();

    const writer = serial.COM1.writer();
    try writer.print("\n{s}", .{motd});
    try writer.print("\n{s}", .{prompt});

    const reader = serial.COM1.reader();
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        switch (byte) {
            '\x08' => try writer.print("\x08 \x08", .{}),
            '\r' => try writer.print("\n{s}", .{prompt}),
            else => try writer.writeByte(byte),
        }
    }
}

fn parsePrompt() ![]const u8 {
    const profile = try initrd.read("./etc/profile");

    const start_quote = std.mem.indexOf(u8, profile, "\"");
    const end_quote = std.mem.lastIndexOf(u8, profile, "\"");

    if (start_quote == null or end_quote == null) {
        return error.MissingQuote;
    }

    const start_index = start_quote.? + 1;
    const end_index = end_quote.?;

    return profile[start_index..end_index];
}
