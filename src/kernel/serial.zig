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

const Log = std.log.scoped(.serial);

const IO = enum(u16) {
    COM1 = 0x3F8,
    COM2 = 0x2F8,
    COM3 = 0x3E8,
    COM4 = 0x2E8,
    COM5 = 0x5F8,
    COM6 = 0x4F8,
    COM7 = 0x5E8,
    COM8 = 0x4E8,
};

const Port = struct {
    address: u16,

    const Reader = std.io.GenericReader(Port, error{}, read);
    const Writer = std.io.GenericWriter(Port, error{}, write);

    pub fn init(port: IO) Port {
        const address: u16 = @intFromEnum(port);

        outb(address + 1, 0x00);
        outb(address + 3, 0x80);
        outb(address + 0, 0x03);
        outb(address + 1, 0x00);
        outb(address + 3, 0x03);
        outb(address + 2, 0xC7);
        outb(address + 4, 0x0B);
        outb(address + 4, 0x1E);
        outb(address + 0, 0xAE);

        if (inb(address + 0) != 0xAE) {
            @panic("Failed to initialize serial port.");
        }

        outb(address + 4, 0x0F);

        return .{ .address = address };
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

    fn received(self: Port) u8 {
        return inb(self.address + 5) & 1;
    }

    fn getCharacter(self: Port) u8 {
        while (self.received() == 0) {}
        return inb(self.address);
    }

    fn transmitEmpty(self: Port) u8 {
        return inb(self.address + 5) & 0x20;
    }

    fn putCharacter(self: Port, character: u8) void {
        while (self.transmitEmpty() == 0) {}
        outb(self.address, character);
    }

    fn read(self: Port, buffer: []u8) !usize {
        buffer[0] = self.getCharacter();
        return 1;
    }

    fn write(self: Port, bytes: []const u8) !usize {
        for (bytes) |byte| {
            if (byte == '\n') {
                self.putCharacter('\r');
            }
            self.putCharacter(byte);
        }
        return bytes.len;
    }

    pub fn reader(self: Port) Reader {
        return .{ .context = self };
    }

    pub fn writer(self: Port) Writer {
        return .{ .context = self };
    }
};

pub var COM1: Port = undefined;

pub fn init() void {
    COM1 = Port.init(IO.COM1);
    Log.info("Initialized the serial console subsystem.", .{});
}
