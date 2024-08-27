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

FROM fedora:40
RUN dnf install -y \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
    --setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' \
    terra-release-40 \
    && dnf clean all
RUN dnf install -y \
    dnf-plugins-core-4.9.0 \
    edk2-ovmf-20240524 \
    gcc-14.2.1 \
    git-2.46.0 \
    gdb-14.2 \
    limine-8.0.6 \
    make-4.4.1 \
    qemu-system-x86-8.2.2 \
    xorriso-1.5.6 \
    && dnf clean all
RUN dnf copr enable -y mczernek/vale \
    && dnf install -y vale \
    && dnf clean all
RUN useradd -m developer
USER developer
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly-2024-08-27 --target x86_64-unknown-none -y
ENV PATH="$PATH:$HOME/.cargo/bin"
