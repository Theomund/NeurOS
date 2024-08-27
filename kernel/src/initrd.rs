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

use crate::logger::{Level, LOGGER};
use crate::{debug, trace};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::fmt::{Display, Formatter};
use core::ptr::slice_from_raw_parts;
use core::str::{from_utf8, FromStr};
use limine::request::ModuleRequest;
use spin::Lazy;

#[used]
#[link_section = ".requests"]
static MODULE_REQUEST: ModuleRequest = ModuleRequest::new();

pub static INITRD: Lazy<Initrd> = Lazy::new(Initrd::new);

const BLOCK_SIZE: usize = 512;
const EOF_BLOCK: [u8; BLOCK_SIZE] = [0; BLOCK_SIZE];

#[derive(Debug)]
struct Header {
    name: String,
    mode: u32,
    user_id: u32,
    group_id: u32,
    size: u32,
    mtime: u32,
    checksum: String,
    flag: u32,
    linked: String,
    indicator: String,
    version: String,
    username: String,
    group: String,
    major: u32,
    minor: u32,
    prefix: String,
}

#[derive(Debug)]
pub struct File {
    header: Header,
    data: Vec<u8>,
}

impl File {
    fn parse_permission(digit: u32) -> String {
        let read = if digit & 0b100 == 0b100 { 'r' } else { '-' };
        let write = if digit & 0b010 == 0b010 { 'w' } else { '-' };
        let execute = if digit & 0b001 == 0b001 { 'x' } else { '-' };
        format!("{read}{write}{execute}")
    }
}

impl Display for File {
    fn fmt(&self, f: &mut Formatter<'_>) -> core::fmt::Result {
        let flag = match self.header.flag {
            5 => 'd',
            _ => '-',
        };
        let digits: Vec<u32> = self
            .header
            .mode
            .to_string()
            .chars()
            .map(|x| x.to_digit(10).unwrap())
            .collect();
        let owner = File::parse_permission(digits[0]);
        let group = File::parse_permission(digits[1]);
        let other = File::parse_permission(digits[2]);
        let permissions = format!("{flag}{owner}{group}{other}");
        write!(
            f,
            "{} {}/{} {} {} {}",
            permissions,
            self.header.username,
            self.header.group,
            self.header.size,
            self.header.mtime,
            self.header.name
        )?;
        Ok(())
    }
}

pub struct Initrd {
    files: Vec<File>,
}

impl Initrd {
    pub fn new() -> Initrd {
        let module = MODULE_REQUEST.get_response().unwrap().modules()[0];
        let mut address = module.addr();
        let mut files: Vec<File> = Vec::new();
        while Initrd::parse_block(address, BLOCK_SIZE) != EOF_BLOCK {
            let header = Initrd::parse_header(address);
            let mut data: Vec<u8> = Vec::new();
            if header.size != 0 {
                address = address.wrapping_add(BLOCK_SIZE);
                data = Initrd::parse_data(address, header.size);
                address = address.wrapping_add(
                    BLOCK_SIZE * header.size.div_ceil(u32::try_from(BLOCK_SIZE).unwrap()) as usize,
                );
            } else {
                address = address.wrapping_add(BLOCK_SIZE);
            }
            let file = File { header, data };
            trace!("{file}");
            files.push(file);
        }
        Initrd { files }
    }

    fn parse_slice(address: *mut u8, length: usize) -> &'static str {
        let slice = slice_from_raw_parts(address, length);
        unsafe { from_utf8(&*slice).unwrap().trim_end_matches('\0') }
    }

    fn parse_string(address: *mut u8, length: usize) -> String {
        let slice = Initrd::parse_slice(address, length);
        slice.to_string()
    }

    fn parse_integer(address: *mut u8, length: usize) -> u32 {
        let slice = Initrd::parse_slice(address, length);
        u32::from_str(slice).unwrap_or(0)
    }

    fn parse_octal(address: *mut u8, length: usize) -> u32 {
        let slice = Initrd::parse_slice(address, length);
        u32::from_str_radix(slice, 8).unwrap()
    }

    fn parse_block(address: *mut u8, length: usize) -> &'static [u8] {
        let slice = slice_from_raw_parts(address, length);
        unsafe { slice.as_ref().unwrap() }
    }

    fn parse_header(address: *mut u8) -> Header {
        Header {
            name: Initrd::parse_string(address, 100),
            mode: Initrd::parse_integer(address.wrapping_add(100), 8),
            user_id: Initrd::parse_octal(address.wrapping_add(108), 8),
            group_id: Initrd::parse_octal(address.wrapping_add(116), 8),
            size: Initrd::parse_octal(address.wrapping_add(124), 12),
            mtime: Initrd::parse_octal(address.wrapping_add(136), 12),
            checksum: Initrd::parse_string(address.wrapping_add(148), 8),
            flag: Initrd::parse_integer(address.wrapping_add(156), 1),
            linked: Initrd::parse_string(address.wrapping_add(157), 100),
            indicator: Initrd::parse_string(address.wrapping_add(257), 6),
            version: Initrd::parse_string(address.wrapping_add(263), 2),
            username: Initrd::parse_string(address.wrapping_add(265), 32),
            group: Initrd::parse_string(address.wrapping_add(297), 32),
            major: Initrd::parse_integer(address.wrapping_add(329), 8),
            minor: Initrd::parse_integer(address.wrapping_add(337), 8),
            prefix: Initrd::parse_string(address.wrapping_add(345), 155),
        }
    }

    fn parse_data(address: *mut u8, length: u32) -> Vec<u8> {
        let slice = slice_from_raw_parts(address, length as usize);
        unsafe { slice.as_ref().unwrap().to_vec() }
    }

    pub fn get_files(&self) -> &Vec<File> {
        &self.files
    }

    pub fn get_data(&self, path: &str) -> &Vec<u8> {
        &self
            .files
            .iter()
            .find(|x| x.header.name == path)
            .unwrap()
            .data
    }
}

pub fn initialize() {
    debug!(
        "Loaded {} files from the initial ramdisk.",
        INITRD.get_files().len()
    );
}
