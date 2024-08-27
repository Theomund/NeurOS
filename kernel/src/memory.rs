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

use limine::memory_map::{Entry, EntryType};
use limine::request::{HhdmRequest, MemoryMapRequest, StackSizeRequest};
use linked_list_allocator::LockedHeap;
use spin::{Lazy, Mutex};
use x86_64::registers::control::Cr3;
use x86_64::structures::paging::page::PageRangeInclusive;
use x86_64::structures::paging::{
    FrameAllocator, Mapper, OffsetPageTable, Page, PageTableFlags, PhysFrame, Size4KiB,
};
use x86_64::{PhysAddr, VirtAddr};

#[used]
#[link_section = ".requests"]
static STACK_SIZE_REQUEST: StackSizeRequest = StackSizeRequest::new().with_size(0x32000);

#[used]
#[link_section = ".requests"]
static MEMORY_MAP_REQUEST: MemoryMapRequest = MemoryMapRequest::new();

#[used]
#[link_section = ".requests"]
static HHDM_REQUEST: HhdmRequest = HhdmRequest::new();

static PHYSICAL_MANAGER: Lazy<Mutex<PhysicalManager>> = Lazy::new(|| {
    let manager = PhysicalManager::new();
    Mutex::new(manager)
});

static VIRTUAL_MANAGER: Lazy<Mutex<VirtualManager>> = Lazy::new(|| {
    let manager = VirtualManager::new();
    Mutex::new(manager)
});

struct PhysicalManager {
    memory_map: &'static [&'static Entry],
    next: usize,
}

impl PhysicalManager {
    fn new() -> PhysicalManager {
        let entries = MEMORY_MAP_REQUEST.get_response().unwrap().entries();
        PhysicalManager {
            memory_map: entries,
            next: 0,
        }
    }

    fn usable_frames(&self) -> impl Iterator<Item = PhysFrame> {
        self.memory_map
            .iter()
            .filter(|x| x.entry_type == EntryType::USABLE)
            .flat_map(|x| (x.base..x.base + x.length).step_by(4096))
            .map(|x| PhysFrame::containing_address(PhysAddr::new(x)))
    }
}

unsafe impl FrameAllocator<Size4KiB> for PhysicalManager {
    fn allocate_frame(&mut self) -> Option<PhysFrame<Size4KiB>> {
        let frame = self.usable_frames().nth(self.next);
        self.next += 1;
        frame
    }
}

struct VirtualManager {
    table: OffsetPageTable<'static>,
}

impl VirtualManager {
    fn new() -> VirtualManager {
        let (level_4_table_frame, _) = Cr3::read();
        let physical_memory_offset = VirtAddr::new(HHDM_REQUEST.get_response().unwrap().offset());
        let physical_address = level_4_table_frame.start_address();
        let virtual_address = physical_memory_offset + physical_address.as_u64();
        let page_table_pointer = virtual_address.as_mut_ptr();
        let table =
            unsafe { OffsetPageTable::new(&mut *page_table_pointer, physical_memory_offset) };
        VirtualManager { table }
    }

    fn allocate_pages(&mut self, range: PageRangeInclusive, manager: &mut PhysicalManager) {
        for page in range {
            let frame = manager.allocate_frame().unwrap();
            let flags = PageTableFlags::PRESENT | PageTableFlags::WRITABLE;
            unsafe {
                self.table
                    .map_to(page, frame, flags, manager)
                    .unwrap()
                    .flush();
            };
        }
    }
}

#[global_allocator]
static ALLOCATOR: LockedHeap = LockedHeap::empty();

const HEAP_START: usize = 0x_4444_4444_0000;
const HEAP_SIZE: usize = 4 * 1024 * 1024;

pub fn initialize() {
    STACK_SIZE_REQUEST.get_response();

    let page_range = {
        let heap_start = VirtAddr::new(HEAP_START as u64);
        let heap_end = heap_start + HEAP_SIZE as u64 - 1;
        let heap_start_page: Page<Size4KiB> = Page::containing_address(heap_start);
        let heap_end_page: Page<Size4KiB> = Page::containing_address(heap_end);
        Page::range_inclusive(heap_start_page, heap_end_page)
    };

    VIRTUAL_MANAGER
        .lock()
        .allocate_pages(page_range, &mut PHYSICAL_MANAGER.lock());

    unsafe {
        ALLOCATOR.lock().init(HEAP_START as *mut u8, HEAP_SIZE);
    }
}
