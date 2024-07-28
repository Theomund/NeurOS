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

const Log = std.log.scoped(.font);

const Header = struct {
    magic: u16,
    font_mode: u8,
    glyph_size: u8,
};

pub const Face = struct {
    header: Header,
    data: []const u8,

    pub fn init(path: []const u8) !Face {
        const psf = try initrd.disk.read(path);
        const header = Header{
            .magic = std.mem.readInt(u16, psf[0..2], .little),
            .font_mode = psf[2],
            .glyph_size = psf[3],
        };
        const data = psf[4..4100];
        const font = Face{
            .header = header,
            .data = data,
        };
        Log.debug("Parsed font face with path {s}.", .{path});
        return font;
    }

    pub fn getWidth(self: Face) usize {
        return self.header.glyph_size / 2;
    }

    pub fn getHeight(self: Face) usize {
        return self.header.glyph_size;
    }
};
