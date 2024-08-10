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

const initrd = @import("initrd.zig");
const std = @import("std");

const Log = std.log.scoped(.image);

const Header = struct {
    width: u16,
    height: u16,
    max_value: u16,
};

const Position = struct {
    x: usize,
    y: usize,
};

const Pixel = struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub const PPM = struct {
    header: Header,
    position: Position,
    pixels: []const Pixel,

    pub fn init(path: []const u8) !PPM {
        const file = try initrd.disk.read(path);

        var iterator = std.mem.tokenizeAny(u8, file, " \t\r\n");

        const magic = iterator.next().?;

        if (!std.mem.eql(u8, magic, "P6")) {
            Log.err("Failed to parse PPM image with path {s}.", .{path});
            return error.InvalidImage;
        }

        const width = try std.fmt.parseInt(u16, iterator.next().?, 10);
        const height = try std.fmt.parseInt(u16, iterator.next().?, 10);
        const max_value = try std.fmt.parseInt(u16, iterator.next().?, 10);

        const header = Header{
            .width = width,
            .height = height,
            .max_value = max_value,
        };

        const position = Position{
            .x = 0,
            .y = 0,
        };

        const pixels: []const Pixel = undefined;

        Log.debug("Parsed PPM image with path {s}.", .{path});

        return .{
            .header = header,
            .position = position,
            .pixels = pixels,
        };
    }
};
