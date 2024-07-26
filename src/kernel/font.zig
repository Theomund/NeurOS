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

const Font = struct {
    header: Header,
    data: []const u8,
};

var normal: Font = undefined;
var bold: Font = undefined;

pub fn init() !void {
    normal = try parse("./usr/share/fonts/ter-i16n.psf");
    bold = try parse("./usr/share/fonts/ter-i16b.psf");
    Log.info("Initialized the font subsystem.", .{});
}

fn parse(path: []const u8) !Font {
    const psf = try initrd.read(path);
    const header = Header{
        .magic = std.mem.readInt(u16, psf[0..2], .little),
        .font_mode = psf[2],
        .glyph_size = psf[3],
    };
    const data = psf[4..4100];
    const font = Font{
        .header = header,
        .data = data,
    };
    Log.debug("Parsed font with path {s}.", .{path});
    return font;
}
