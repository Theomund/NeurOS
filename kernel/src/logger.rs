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

use crate::serial::SERIAL;
use crate::shell::{BLUE, DEFAULT, GREEN, ORANGE, PURPLE, RED, YELLOW};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::fmt::Write;
use core::fmt::{Display, Formatter, Result};
use spin::{Lazy, Mutex};

pub static LOGGER: Lazy<Mutex<Logger>> = Lazy::new(|| {
    let logger = Logger::new();
    Mutex::new(logger)
});

#[macro_export]
macro_rules! debug {
    ($message:expr) => {
        LOGGER.lock().debug($message);
    };
}

#[macro_export]
macro_rules! error {
    ($message:expr) => {
        LOGGER.lock().error($message);
    };
}

#[macro_export]
macro_rules! fatal {
    ($message:expr) => {
        Logger::fatal($message);
    };
}

#[macro_export]
macro_rules! info {
    ($message:expr) => {
        LOGGER.lock().info($message);
    };
}

#[macro_export]
macro_rules! trace {
    ($message:expr) => {
        LOGGER.lock().trace($message);
    };
}

#[macro_export]
macro_rules! warn {
    ($message:expr) => {
        LOGGER.lock().warn($message);
    };
}

enum Level {
    Fatal,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

pub struct Log {
    level: Level,
    message: String,
}

impl Display for Log {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        let label = match self.level {
            Level::Debug => format!("{GREEN}[DEBUG]{DEFAULT}"),
            Level::Error => format!("{RED}[ERROR]{DEFAULT}"),
            Level::Fatal => format!("{ORANGE}[FATAL]{DEFAULT}"),
            Level::Info => format!("{BLUE}[INFO]{DEFAULT}"),
            Level::Trace => format!("{PURPLE}[TRACE]{DEFAULT}"),
            Level::Warn => format!("{YELLOW}[WARN]{DEFAULT}"),
        };
        write!(f, "{} {}", label, self.message)?;
        Ok(())
    }
}

pub struct Logger {
    logs: Vec<Log>,
}

impl Logger {
    pub fn new() -> Logger {
        Logger { logs: Vec::new() }
    }

    pub fn debug(&mut self, message: &str) {
        let log = Log {
            level: Level::Debug,
            message: message.to_string(),
        };
        self.logs.push(log);
    }

    pub fn error(&mut self, message: &str) {
        let log = Log {
            level: Level::Error,
            message: message.to_string(),
        };
        self.logs.push(log);
    }

    pub fn fatal(message: &str) {
        let log = Log {
            level: Level::Fatal,
            message: message.to_string(),
        };
        write!(SERIAL.lock(), "{log}").unwrap();
    }

    pub fn info(&mut self, message: &str) {
        let log = Log {
            level: Level::Info,
            message: message.to_string(),
        };
        self.logs.push(log);
    }

    pub fn trace(&mut self, message: &str) {
        let log = Log {
            level: Level::Trace,
            message: message.to_string(),
        };
        self.logs.push(log);
    }

    pub fn warn(&mut self, message: &str) {
        let log = Log {
            level: Level::Warn,
            message: message.to_string(),
        };
        self.logs.push(log);
    }

    pub fn get_logs(&self) -> &Vec<Log> {
        &self.logs
    }
}
