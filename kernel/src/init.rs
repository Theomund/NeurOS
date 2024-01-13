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

use crate::font::Font;
use crate::vga::Vga;

pub fn run() {
    let font = Font::new();
    let vga = Vga::new(font);
    let version = concat!(
        "Version ",
        env!("CARGO_PKG_VERSION"),
        " (",
        env!("COMMIT_HASH"),
        ")"
    );
    vga.write(
        version,
        font.get_width(),
        vga.get_height() - font.get_width(),
    );
    let copyright = concat!("Copyright (C) 2024 ", env!("CARGO_PKG_AUTHORS"));
    vga.write(
        copyright,
        vga.get_width() - (copyright.len() * font.get_width() + font.get_width()),
        vga.get_height() - font.get_width(),
    )
}