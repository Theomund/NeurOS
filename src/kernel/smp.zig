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

const Log = std.log.scoped(.smp);

pub export var smp_request: limine.SmpRequest = .{};

pub fn init() !void {
    try getCoreCount();
    Log.info("Initialized the SMP subsystem.", .{});
}

fn getCoreCount() !void {
    if (smp_request.response) |smp_response| {
        const count = smp_response.cpu_count;
        Log.debug("Detected {d} core(s) in the CPU processor.", .{count});
    } else {
        Log.err("Failed to retrieve SMP response.", .{});
        return error.MissingResponse;
    }
}
