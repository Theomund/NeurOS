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

const std = @import("std");

const Context = struct {};
const Log = std.log.scoped(.serial);
const ReadError = error{};
const WriteError = error{};
pub const Reader = std.io.GenericReader(Context, ReadError, read);
pub const Writer = std.io.GenericWriter(Context, WriteError, write);

const port = 0x3f8;

pub fn init() void {
    outb(port + 1, 0x00);
    outb(port + 3, 0x80);
    outb(port + 0, 0x03);
    outb(port + 1, 0x00);
    outb(port + 3, 0x03);
    outb(port + 2, 0xC7);
    outb(port + 4, 0x0B);
    outb(port + 4, 0x1E);
    outb(port + 0, 0xAE);

    if (inb(port + 0) != 0xAE) {
        @panic("Failed to initialize serial port.");
    }

    outb(port + 4, 0x0F);

    Log.info("Initialized the serial console subsystem.", .{});
}

fn inb(address: u16) u8 {
    return asm volatile ("inb %[address], %[value]"
        : [value] "={al}" (-> u8),
        : [address] "N{dx}" (address),
    );
}

fn outb(address: u16, value: u8) void {
    asm volatile ("outb %[value], %[address]"
        :
        : [address] "{dx}" (address),
          [value] "{al}" (value),
    );
}

fn received() u8 {
    return inb(port + 5) & 1;
}

fn getchar() u8 {
    while (received() == 0) {}
    return inb(port);
}

fn transmitEmpty() u8 {
    return inb(port + 5) & 0x20;
}

fn putc(character: u8) void {
    while (transmitEmpty() == 0) {}
    outb(port, character);
}

fn read(context: Context, buffer: []u8) ReadError!usize {
    _ = context;
    buffer[0] = getchar();
    return 1;
}

fn write(context: Context, bytes: []const u8) WriteError!usize {
    _ = context;
    for (bytes) |byte| {
        if (byte == '\n') {
            putc('\r');
        }
        putc(byte);
    }
    return bytes.len;
}
