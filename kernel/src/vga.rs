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

use crate::ansi::{BLUE, BOLD, DEFAULT, GREEN, NORMAL, ORANGE, PURPLE, RED, YELLOW};
use crate::font::Font;
use alloc::format;
use alloc::string::{String, ToString};
use core::fmt::{Arguments, Result, Write};
use core::ptr;
use core::sync::atomic::{AtomicPtr, Ordering};
use limine::request::FramebufferRequest;
use spin::{Lazy, Mutex};
use x86_64::instructions::interrupts::without_interrupts;

#[used]
#[link_section = ".requests"]
static FRAMEBUFFER_REQUEST: FramebufferRequest = FramebufferRequest::new();

pub static VGA: Lazy<Mutex<Vga>> = Lazy::new(|| {
    let font = Font::new("initrd/usr/share/fonts/ter-i16n.psf");
    let vga = Vga::new(font);
    Mutex::new(vga)
});

#[derive(Clone, Copy)]
pub enum Color {
    Black = 0x0,
    Blue = 0x0000_97E6,
    Green = 0x0044_BD32,
    Orange = 0x00C2_3616,
    Purple = 0x008C_7AE6,
    Red = 0x00E8_4118,
    White = 0x00F5_F6FA,
    Yellow = 0x00FB_C531,
}

struct Cursor {
    x: usize,
    y: usize,
    fg: u32,
    bg: u32,
}

pub struct Vga {
    address: AtomicPtr<u8>,
    cursor: Cursor,
    font: Font,
    height: u64,
    pitch: u64,
    width: u64,
}

impl Write for Vga {
    fn write_str(&mut self, s: &str) -> Result {
        let mut x = self.cursor.x;
        let mut y = self.cursor.y;
        let mut fg = self.cursor.fg;
        let bg = self.cursor.bg;

        let chars = &mut s.chars();
        let mut position = 0;

        while let Some(character) = chars.next() {
            match character {
                '\n' => {
                    x = self.font.get_width();
                    y += self.font.get_height();
                    position = 0;
                    self.set_cursor(x, y, fg, bg);
                }
                '\r' => {
                    x = self.font.get_width();
                    position = 0;
                    self.set_cursor(x, y, fg, bg);
                }
                '\t' => {
                    x += self.font.get_width() * 8;
                    self.set_cursor(x, y, fg, bg);
                }
                '\x1b' => {
                    let mut sequence: String = chars.take_while(|x| *x != 'm').collect();
                    sequence = format!("\x1b{sequence}m");
                    match sequence.as_str() {
                        BOLD => {
                            self.font = Font::new("initrd/usr/share/fonts/ter-i16b.psf");
                        }
                        BLUE => {
                            fg = Color::Blue as u32;
                        }
                        DEFAULT => {
                            fg = Color::White as u32;
                        }
                        GREEN => {
                            fg = Color::Green as u32;
                        }
                        NORMAL => {
                            self.font = Font::new("initrd/usr/share/fonts/ter-i16n.psf");
                        }
                        ORANGE => {
                            fg = Color::Orange as u32;
                        }
                        PURPLE => {
                            fg = Color::Purple as u32;
                        }
                        RED => {
                            fg = Color::Red as u32;
                        }
                        YELLOW => {
                            fg = Color::Yellow as u32;
                        }
                        _ => {}
                    }
                }
                _ => {
                    self.set_cursor(x + self.font.get_width() * position, y, fg, bg);
                    self.write_char(character)?;
                    position += 1;
                }
            }
        }

        Ok(())
    }

    fn write_char(&mut self, c: char) -> Result {
        let masks = [128, 64, 32, 16, 8, 4, 2, 1];
        let position = c as usize * self.font.get_height();
        let glyphs = &self.font.get_data()[position..];

        let x = self.cursor.x;
        let y = self.cursor.y;
        let fg = self.cursor.fg;
        let bg = self.cursor.bg;

        for (cy, glyph) in glyphs.iter().enumerate().take(self.font.get_height()) {
            for (cx, mask) in masks.iter().enumerate().take(self.font.get_width()) {
                let color = if glyph & mask == 0 { bg } else { fg };
                self.draw_pixel(x + cx, y + cy - 12, color);
            }
        }

        Ok(())
    }

    fn write_fmt(&mut self, args: Arguments<'_>) -> Result {
        without_interrupts(|| {
            self.write_str(args.to_string().as_str())?;
            Ok(())
        })
    }
}

impl Vga {
    pub fn new(font: Font) -> Vga {
        if let Some(framebuffer_response) = FRAMEBUFFER_REQUEST.get_response() {
            let framebuffer = framebuffer_response.framebuffers().next().unwrap();
            Vga {
                address: AtomicPtr::new(framebuffer.addr()),
                cursor: Cursor {
                    x: 0,
                    y: 0,
                    fg: Color::White as u32,
                    bg: Color::Black as u32,
                },
                font,
                height: framebuffer.height(),
                pitch: framebuffer.pitch(),
                width: framebuffer.width(),
            }
        } else {
            panic!("Failed to initialize VGA module.");
        }
    }

    pub fn clear(&mut self) {
        for y in 0..self.height {
            for x in 0..self.width {
                self.draw_pixel(
                    usize::try_from(x).unwrap(),
                    usize::try_from(y).unwrap(),
                    Color::Black as u32,
                );
            }
        }
        self.set_cursor(8, 24, Color::White as u32, Color::Black as u32);
    }

    pub fn draw_pixel(&self, x: usize, y: usize, color: u32) {
        let offset = y * usize::try_from(self.pitch).unwrap() + x * 4;
        let pixel = self.address.load(Ordering::Relaxed).wrapping_add(offset);
        unsafe {
            ptr::write_unaligned(pixel.cast::<u32>(), color);
        }
    }

    pub fn get_width(&self) -> usize {
        usize::try_from(self.width).unwrap()
    }

    pub fn get_height(&self) -> usize {
        usize::try_from(self.height).unwrap()
    }

    pub fn get_font_width(&self) -> usize {
        self.font.get_width()
    }

    pub fn get_font_height(&self) -> usize {
        self.font.get_height()
    }

    pub fn set_cursor(&mut self, x: usize, y: usize, fg: u32, bg: u32) {
        self.cursor = Cursor { x, y, fg, bg }
    }
}
