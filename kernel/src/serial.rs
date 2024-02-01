// NeurOS - Hobbyist operating system written in Rust.
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

use alloc::string::ToString;
use core::arch::asm;
use core::fmt;
use core::fmt::Arguments;
use spin::{Lazy, Mutex};

pub static SERIAL: Lazy<Mutex<Serial>> = Lazy::new(|| {
    let serial = Serial::new(Port::COM1);
    serial.initialize();
    Mutex::new(serial)
});

pub struct Serial {
    address: u16,
}

pub enum Port {
    COM1 = 0x3F8,
}

impl fmt::Write for Serial {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for character in s.chars() {
            self.write_char(character)?;
        }
        Ok(())
    }

    fn write_char(&mut self, c: char) -> fmt::Result {
        while self.transmit_empty() == 0 {}
        self.outb(0, c as u8);
        Ok(())
    }

    fn write_fmt(&mut self, args: Arguments<'_>) -> fmt::Result {
        self.write_str(args.to_string().as_str())?;
        Ok(())
    }
}

impl Serial {
    pub fn new(port: Port) -> Serial {
        Serial {
            address: port as u16,
        }
    }

    pub fn initialize(&self) {
        self.outb(1, 0x00);
        self.outb(3, 0x80);
        self.outb(0, 0x03);
        self.outb(1, 0x00);
        self.outb(3, 0x03);
        self.outb(2, 0xC7);
        self.outb(4, 0x0B);
        self.outb(4, 0x1E);
        self.outb(0, 0xAE);

        if self.inb(0) != 0xAE {
            panic!("Failed to initialize serial port.");
        }

        self.outb(4, 0x0F);
    }

    fn inb(&self, offset: u16) -> u8 {
        let port = self.address + offset;
        let value: u8;
        unsafe {
            asm!("inb %dx, %al", in("dx") port, out("al") value, options(att_syntax));
        }
        value
    }

    fn outb(&self, offset: u16, value: u8) {
        let port = self.address + offset;
        unsafe {
            asm!("outb %al, %dx", in("al") value, in("dx") port, options(att_syntax));
        }
    }

    fn transmit_empty(&self) -> u8 {
        self.inb(5) & 0x20
    }

    fn received(&self) -> u8 {
        self.inb(5) & 0x1
    }

    pub fn read(&self) -> u8 {
        while self.received() == 0 {}
        self.inb(0)
    }
}