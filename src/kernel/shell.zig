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

pub fn init() void {
    const writer = serial.Writer{ .context = .{} };
    const motd = "\n{s}{s}NeurOS v0.1.0 (x86_64)\r\n{s}Copyright (C) 2024 Theomund{s}{s}\n";
    const prompt = "\r\n{s}[{s}root@localhost{s} ~{s}]# ";

    try writer.print(motd, .{ ansi.bold, ansi.red, ansi.blue, ansi.normal, ansi.default });
    try writer.print(prompt, .{ ansi.bold, ansi.green, ansi.blue, ansi.default });

    const reader = serial.Reader{ .context = .{} };
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        switch (byte) {
            '\x08' => try writer.print("\x08 \x08", .{}),
            '\r' => try writer.print(prompt, .{ ansi.bold, ansi.green, ansi.blue, ansi.default }),
            else => try writer.writeByte(byte),
        }
    }
}
