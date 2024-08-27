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

use acpi::{AcpiHandler, AcpiTables, PhysicalMapping};
use limine::request::RsdpRequest;

#[used]
#[link_section = ".requests"]
static RSDP_REQUEST: RsdpRequest = RsdpRequest::new();

#[derive(Clone)]
struct Handler;

impl AcpiHandler for Handler {
    unsafe fn map_physical_region<T>(
        &self,
        physical_address: usize,
        size: usize,
    ) -> PhysicalMapping<Self, T> {
        todo!()
    }

    fn unmap_physical_region<T>(region: &PhysicalMapping<Self, T>) {
        todo!()
    }
}

struct Acpi {
    tables: AcpiTables<Handler>,
}

impl Acpi {
    pub fn new() -> Acpi {
        let rsdp = RSDP_REQUEST.get_response().unwrap().address() as usize;
        let handler = Handler;
        unsafe {
            let tables = AcpiTables::from_rsdp(handler, rsdp).unwrap();
            Acpi { tables }
        }
    }
}
