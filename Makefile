# NeurOS - Hobbyist operating system written in Rust.
# Copyright (C) 2024 Theomund
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

SHELL := /bin/sh

DEBUG := false
PROFILE := dev

ifeq ($(DEBUG),true)
    DEBUG_FLAGS := -s -S
endif

ifeq ($(PROFILE),dev)
    SUBDIR := debug
else
    SUBDIR := $(PROFILE)
endif

DATA_DIRECTORY := $(shell limine --print-datadir)/

BIN_FOLDER := initrd/bin
BIOS_FILES := $(addprefix $(DATA_DIRECTORY),limine-bios.sys limine-bios-cd.bin limine-uefi-cd.bin)
BOOT_CONFIG := bootloader/limine.conf
EFI_FILES := $(addprefix $(DATA_DIRECTORY),BOOTX64.EFI BOOTIA32.EFI)
INIT := $(BIN_FOLDER)/init
INITRD := target/initrd.tar
INITRD_SOURCE := $(shell find initrd)
INIT_SOURCE := $(shell find userland/init)
ISO := target/NeurOS.iso
ISO_ROOT := target/iso_root
KERNEL := target/x86_64-unknown-none/$(SUBDIR)/kernel
KERNEL_SOURCE := $(shell find kernel)
SOURCE_DATE_EPOCH := $(shell git log -1 --format=%ct)
STYLE := .github/styles/RedHat

BUILD_DATE := $(shell date -u -d @$(SOURCE_DATE_EPOCH) +'%Y%m%d%H%M.%S')

$(ISO): $(BIOS_FILES) $(EFI_FILES) $(LIMINE) $(KERNEL) $(INITRD)
	mkdir -p $(ISO_ROOT)/EFI/BOOT
	cp -v $(BIOS_FILES) $(BOOT_CONFIG) $(INITRD) $(KERNEL) $(ISO_ROOT)
	cp -v $(EFI_FILES) $(ISO_ROOT)/EFI/BOOT/
	xorriso -as mkisofs -b limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		--set_all_file_dates $(BUILD_DATE) \
		$(ISO_ROOT) -o $(ISO)
	limine bios-install $(ISO)
	rm -rf $(ISO_ROOT)

$(INIT): $(INIT_SOURCE)
	cargo build --profile $(PROFILE) --package init
	mkdir -p initrd/bin
	cp target/x86_64-unknown-none/$(SUBDIR)/init $(BIN_FOLDER)

$(INITRD): $(INITRD_SOURCE) $(INIT)
	tar --format ustar -c -f $(INITRD) initrd

$(KERNEL): $(KERNEL_SOURCE)
	cargo build --profile $(PROFILE) --package kernel

$(STYLE):
	vale sync

.PHONY: all
all: $(ISO)

.PHONY: clean
clean:
	cargo clean
	rm -rf $(BIN_FOLDER)

.PHONY: debug
debug: $(KERNEL)
	rust-gdb -ex "file $(KERNEL)" -ex "target remote localhost:1234"

.PHONY: distclean
distclean: clean
	rm -rf $(STYLE)

.PHONY: format
format:
	cargo fmt

.PHONY: lint
lint: $(STYLE)
	cargo clippy --profile $(PROFILE)
	vale README.md

.PHONY: run
run: $(ISO)
	qemu-system-x86_64 $(DEBUG_FLAGS) -M q35 -m 2G -cdrom $(ISO) -boot d

.PHONY: run-uefi
run-uefi: $(ISO) $(OVMF)
	qemu-system-x86_64 $(DEBUG_FLAGS) -M q35 -m 2G -bios $(OVMF) -cdrom $(ISO) -boot d
