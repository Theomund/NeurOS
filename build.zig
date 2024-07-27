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

pub fn build(b: *std.Build) void {
    var target: std.zig.CrossTarget = .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    };

    const features = std.Target.x86.Feature;
    target.cpu_features_sub.addFeature(@intFromEnum(features.mmx));
    target.cpu_features_sub.addFeature(@intFromEnum(features.sse));
    target.cpu_features_sub.addFeature(@intFromEnum(features.sse2));
    target.cpu_features_sub.addFeature(@intFromEnum(features.avx));
    target.cpu_features_sub.addFeature(@intFromEnum(features.avx2));
    target.cpu_features_add.addFeature(@intFromEnum(features.soft_float));

    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const limine = b.dependency("limine", .{});

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/kernel/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .code_model = .kernel,
        .pic = true,
    });
    kernel.root_module.addImport("limine", limine.module("limine"));
    kernel.setLinkerScriptPath(b.path("src/kernel/linker.ld"));
    kernel.want_lto = false;

    const kernel_artifact = b.addInstallArtifact(kernel, .{});

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel_artifact.step);

    const initrd_cmd = b.addSystemCommand(&.{"tar"});
    initrd_cmd.addArg("--format");
    initrd_cmd.addArg("ustar");
    initrd_cmd.addArg("-c");
    initrd_cmd.addArg("-f");
    const initrd_path = initrd_cmd.addOutputFileArg("initrd.tar");
    initrd_cmd.addArg("-C");
    initrd_cmd.addDirectoryArg(b.path("src/initrd"));
    initrd_cmd.addArg(".");

    const initrd_artifact = b.addInstallFile(initrd_path, "bin/initrd.tar");

    const initrd_step = b.step("initrd", "Build the initial ramdisk");
    initrd_step.dependOn(&initrd_artifact.step);

    const limine_data = "/usr/share/limine";
    const limine_bios_cd = b.fmt("{s}/limine-bios-cd.bin", .{limine_data});
    const limine_bios_sys = b.fmt("{s}/limine-bios.sys", .{limine_data});
    const limine_config = b.path("src/bootloader/limine.cfg");
    const limine_uefi_cd = b.fmt("{s}/limine-uefi-cd.bin", .{limine_data});

    const install_bin_cmd = b.addSystemCommand(&.{"install"});
    install_bin_cmd.addArg("-D");
    install_bin_cmd.addArg("-t");
    install_bin_cmd.addArg(b.exe_dir);
    install_bin_cmd.addArg("-m");
    install_bin_cmd.addArg("700");
    install_bin_cmd.addArg(limine_bios_cd);
    install_bin_cmd.addArg(limine_bios_sys);
    install_bin_cmd.addFileArg(limine_config);
    install_bin_cmd.addArg(limine_uefi_cd);

    const boot_ia32 = b.fmt("{s}/BOOTIA32.EFI", .{limine_data});
    const boot_x64 = b.fmt("{s}/BOOTX64.EFI", .{limine_data});
    const efi_boot = b.fmt("{s}/EFI/BOOT", .{b.exe_dir});

    const install_efi_cmd = b.addSystemCommand(&.{"install"});
    install_efi_cmd.addArg("-D");
    install_efi_cmd.addArg("-t");
    install_efi_cmd.addArg(efi_boot);
    install_efi_cmd.addArg("-m");
    install_efi_cmd.addArg("700");
    install_efi_cmd.addArg(boot_ia32);
    install_efi_cmd.addArg(boot_x64);

    const iso_cmd = b.addSystemCommand(&.{"xorriso"});
    iso_cmd.step.dependOn(kernel_step);
    iso_cmd.step.dependOn(initrd_step);
    iso_cmd.step.dependOn(&install_bin_cmd.step);
    iso_cmd.step.dependOn(&install_efi_cmd.step);
    iso_cmd.addArg("-as");
    iso_cmd.addArg("mkisofs");
    iso_cmd.addArg("-b");
    iso_cmd.addArg("limine-bios-cd.bin");
    iso_cmd.addArg("-no-emul-boot");
    iso_cmd.addArg("-boot-load-size");
    iso_cmd.addArg("4");
    iso_cmd.addArg("-boot-info-table");
    iso_cmd.addArg("--efi-boot");
    iso_cmd.addArg("limine-uefi-cd.bin");
    iso_cmd.addArg("-efi-boot-part");
    iso_cmd.addArg("--efi-boot-image");
    iso_cmd.addArg("--protective-msdos-label");
    iso_cmd.addArg(b.exe_dir);
    iso_cmd.addArg("-o");
    const iso_path = iso_cmd.addOutputFileArg("NeurOS.iso");

    const limine_cmd = b.addSystemCommand(&.{"limine"});
    limine_cmd.addArg("bios-install");
    limine_cmd.addFileArg(iso_path);

    const iso_artifact = b.addInstallFile(iso_path, "NeurOS.iso");
    iso_artifact.step.dependOn(&limine_cmd.step);

    const iso_step = b.step("iso", "Build the ISO");
    iso_step.dependOn(&iso_artifact.step);

    const debug = b.option(bool, "debug", "Enable QEMU Debugging") orelse false;
    const uefi = b.option(bool, "uefi", "Enable UEFI Firmware") orelse false;

    const run_cmd = b.addSystemCommand(&.{"qemu-system-x86_64"});
    run_cmd.step.dependOn(iso_step);
    run_cmd.addArg("-M");
    run_cmd.addArg("q35");
    run_cmd.addArg("-m");
    run_cmd.addArg("2G");
    run_cmd.addArg("-cdrom");
    run_cmd.addArg("zig-out/NeurOS.iso");
    run_cmd.addArg("-boot");
    run_cmd.addArg("d");
    if (debug) {
        run_cmd.addArg("-s");
        run_cmd.addArg("-S");
    }
    if (uefi) {
        run_cmd.addArg("-bios");
        run_cmd.addArg("/usr/share/OVMF/OVMF_CODE.fd");
    }

    const run_step = b.step("run", "Run the operating system");
    run_step.dependOn(&run_cmd.step);

    const clean_cmd = b.addSystemCommand(&.{"rm"});
    clean_cmd.addArg("-rf");
    clean_cmd.addArg(".zig-cache");
    clean_cmd.addArg("zig-out");

    const clean_step = b.step("clean", "Clean the project");
    clean_step.dependOn(&clean_cmd.step);

    const vale_sync_cmd = b.addSystemCommand(&.{"vale"});
    vale_sync_cmd.addArg("sync");

    const vale_cmd = b.addSystemCommand(&.{"vale"});
    vale_cmd.step.dependOn(&vale_sync_cmd.step);
    vale_cmd.addFileArg(b.path("README.md"));

    const lint_step = b.step("lint", "Lint the project");
    lint_step.dependOn(&vale_cmd.step);

    const debug_cmd = b.addSystemCommand(&.{"gdb"});
    debug_cmd.addArg("-ex");
    debug_cmd.addArg("target remote localhost:1234");

    const debug_step = b.step("debug", "Run the GDB debugger");
    debug_step.dependOn(&debug_cmd.step);

    const format_zig_cmd = b.addSystemCommand(&.{"zig"});
    format_zig_cmd.addArg("fmt");
    format_zig_cmd.addArg(".");

    const format_step = b.step("format", "Format the source code");
    format_step.dependOn(&format_zig_cmd.step);

    b.default_step = iso_step;
}
