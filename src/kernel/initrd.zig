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
    indicator: [6]u6,
    version: [2]u8,
    username: [32]u8,
    group: [32]u8,
    major: [8]u8,
    minor: [8]u8,
    prefix: [155]u8,
};

const File = struct {
    header: Header,
    data: *const u8,
};

pub fn init() void {
    if (module_request.response) |module_response| {
        const initrd = module_response.modules()[0];
        Log.debug("Detected initial RAM disk module with {s} as its path ({d} bytes).", .{ initrd.path, initrd.size });
        Log.info("Initialized the initial RAM disk (initrd) subsystem.", .{});
    }
}
