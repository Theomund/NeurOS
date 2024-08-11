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
    data: []const u8,
};

const block_size = 512;

const Disk = struct {
    files: std.ArrayList(File),

    fn init() !Disk {
        return .{
            .files = try parseModule(),
        };
    }

    fn parseModule() !std.ArrayList(File) {
        if (module_request.response) |module_response| {
            const initrd = module_response.modules()[0];
            Log.debug("Detected initial RAM disk module with {s} as its path ({d} bytes).", .{ initrd.path, initrd.size });

            var buffer: [1048576]u8 = undefined;
            var fba = std.heap.FixedBufferAllocator.init(&buffer);
            const allocator = fba.allocator();

            var files = std.ArrayList(File).init(allocator);

            var address = initrd.address;
            while (parseFile(address)) |file| {
                const mode = try parseMode(&file.header.mode);
                const size = try parseOctal(&file.header.size);
                const timestamp = try parseTimestamp(&file.header.mtime);

                Log.debug("{s} {s}/{s} {d} {s} {s}", .{ mode, file.header.username, file.header.group, size, timestamp, file.header.name });

                try files.append(file);

                address += block_size + block_size * try std.math.divCeil(u64, size, block_size);
            } else |_| {
                Log.debug("Finished parsing {d} files from the initial RAM disk.", .{files.items.len});
                return files;
            }
        } else {
            Log.err("Failed to retrieve a module response.", .{});
            return error.MissingModule;
        }
    }

    fn parseMode(mode: []const u8) ![9]u8 {
        var buffer: [9]u8 = undefined;

        const permissions = trim(mode);

        for (0..3, permissions) |i, digit| {
            const symbol = switch (digit) {
                '0' => "---",
                '1' => "--x",
                '2' => "-w-",
                '3' => "-wx",
                '4' => "r--",
                '5' => "r-x",
                '6' => "rw-",
                '7' => "rwx",
                else => return error.InvalidDigit,
            };

            buffer[i * 3] = symbol[0];
            buffer[i * 3 + 1] = symbol[1];
            buffer[i * 3 + 2] = symbol[2];
        }

        return buffer;
    }

    fn parseTimestamp(timestamp: []const u8) ![]const u8 {
        var total_seconds = try parseOctal(timestamp);

        const seconds_in_day: u64 = std.time.s_per_day;
        const seconds_in_leap_year = seconds_in_day * 366;
        var year: std.time.epoch.Year = 1970;

        while (total_seconds > seconds_in_leap_year) {
            total_seconds -= seconds_in_day * std.time.epoch.getDaysInYear(year);
            year += 1;
        }

        var month: u8 = 1;
        const is_leap_year = if (std.time.epoch.isLeapYear(year)) std.time.epoch.YearLeapKind.leap else std.time.epoch.YearLeapKind.not_leap;

        while (total_seconds > seconds_in_day * std.time.epoch.getDaysInMonth(is_leap_year, @enumFromInt(month))) {
            total_seconds -= seconds_in_day * std.time.epoch.getDaysInMonth(is_leap_year, @enumFromInt(month));
            month += 1;
        }

        var day: u8 = 1;

        while (total_seconds > seconds_in_day) {
            total_seconds -= seconds_in_day;
            day += 1;
        }

        var hour: u8 = 0;

        while (total_seconds > std.time.s_per_hour) {
            total_seconds -= std.time.s_per_hour;
            hour += 1;
        }

        var minute: u8 = 0;

        while (total_seconds > std.time.s_per_min) {
            total_seconds -= std.time.s_per_min;
            minute += 1;
        }

        var buffer: [16]u8 = undefined;
        const slice = try std.fmt.bufPrint(&buffer, "{d}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}", .{ year, month, day, hour, minute });

        return slice;
    }

    fn parseFile(address: [*]u8) !File {
        const header = std.mem.bytesToValue(Header, address);

        if (!std.mem.eql(u8, &header.indicator, "ustar\x00")) {
            return error.InvalidFile;
        }

        const size = try parseOctal(&header.size);
        const data = address[block_size .. block_size + size];

        return File{ .header = header, .data = data };
    }

    fn parseOctal(raw: []const u8) !u64 {
        const octal = trim(raw);

        if (octal.len == 0) {
            return 0;
        }

        return std.fmt.parseInt(u64, octal, 8);
    }

    pub fn read(self: Disk, path: []const u8) ![]const u8 {
        for (self.files.items) |file| {
            const name = trim(&file.header.name);

            if (std.mem.eql(u8, name, path)) {
                return file.data;
            }
        }
        return error.FileNotFound;
    }

    fn trim(raw: []const u8) []const u8 {
        const left_trimmed = std.mem.trimLeft(u8, raw, "0");
        const right_trimmed = std.mem.trimRight(u8, left_trimmed, "\x00");
        return right_trimmed;
    }
};

pub var disk: Disk = undefined;

pub fn init() !void {
    disk = try Disk.init();
    Log.info("Initialized the initial RAM disk (initrd) subsystem.", .{});
}

test "Octal Parsing" {
    const decimal = try Disk.parseOctal("0100");
    try std.testing.expectEqual(64, decimal);
}
