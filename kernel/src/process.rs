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

use alloc::string::{String, ToString};

#[derive(Clone)]
pub enum State {
    Running,
    Stopped,
}

#[derive(Clone, Default)]
#[repr(C)]
pub struct Context {
    rax: u64,
    rbx: u64,
    rcx: u64,
    rdx: u64,
    rsi: u64,
    rdi: u64,
    rsp: u64,
    rbp: u64,
    r8: u64,
    r9: u64,
    r10: u64,
    r11: u64,
    r12: u64,
    r13: u64,
    r14: u64,
    r15: u64,
    rip: u64,
    rflags: u64,
}

#[derive(Clone)]
pub struct Process {
    id: u64,
    context: Context,
    name: String,
    state: State,
}

impl Process {
    pub fn new(id: u64, name: &str, state: State) -> Process {
        Process {
            id,
            context: Context::default(),
            name: name.to_string(),
            state,
        }
    }

    pub fn get_id(&self) -> u64 {
        self.id
    }

    pub fn get_name(&self) -> &str {
        self.name.as_str()
    }

    pub fn set_id(&mut self, id: u64) {
        self.id = id;
    }

    pub fn set_state(&mut self, state: State) {
        self.state = state;
    }
}
