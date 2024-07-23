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

const Log = std.log.scoped(.initrd);

pub export var module_request: limine.ModuleRequest = .{};

const Header = struct {
    name: [100]u8,
    mode: [8]u8,
    uid: [8]u8,
    gid: [8]u8,
    size: [12]u8,
    mtime: [12]u8,
    checksum: [8]u8,
    flag: u8,
    linked: [100]u8,
    indicator: [6]u8,
    version: [2]u8,
    username: [32]u8,
    group: [32]u8,
    major: [8]u8,
    minor: [8]u8,
    prefix: [155]u8,
};

const File = struct {
    header: Header,
    data: []u8,
};

const block_size = 512;

pub fn init() void {
    if (module_request.response) |module_response| {
        const initrd = module_response.modules()[0];
        Log.debug("Detected initial RAM disk module with {s} as its path ({d} bytes).", .{ initrd.path, initrd.size });
        var address = initrd.address;
        while (parseFile(address)) |file| {
            const size = parseOctal(&file.header.size);
            Log.debug("{s} {s}/{s} {d} {s} {s}", .{ file.header.mode, file.header.username, file.header.group, size, file.header.mtime, file.header.name });
            address += block_size + block_size * (std.math.divCeil(u64, size, block_size) catch unreachable);
        } else |_| {
            Log.debug("Finished parsing the initial RAM disk.", .{});
        }
        Log.info("Initialized the initial RAM disk (initrd) subsystem.", .{});
    } else {
        Log.err("Failed to initialize the initial RAM disk (initrd) subsystem.", .{});
    }
}

fn parseFile(address: [*]u8) !File {
    const header = std.mem.bytesToValue(Header, address);
    if (!std.mem.eql(u8, &header.indicator, "ustar\x00")) {
        return error.InvalidFile;
    }
    const size = parseOctal(&header.size);
    const data = address[block_size .. block_size + size];
    return File{ .header = header, .data = data };
}

fn parseOctal(raw: []const u8) u64 {
    const left_trimmed = std.mem.trimLeft(u8, raw, "0");
    const right_trimmed = std.mem.trimRight(u8, left_trimmed, "\x00");
    if (right_trimmed.len == 0) {
        return 0;
    }
    return std.fmt.parseInt(u64, right_trimmed, 8) catch unreachable;
}
