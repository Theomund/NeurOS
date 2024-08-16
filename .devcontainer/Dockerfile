# NeurOS - Hobbyist operating system written in Zig.
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

FROM registry.fedoraproject.org/fedora-toolbox:40
RUN dnf copr enable -y mczernek/vale
RUN dnf install -y \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
    --setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' \
    terra-release-40 \
    && dnf install -y \
       gdb-14.2 \
       limine-8.0.5 \
       qemu-system-x86-8.2.2 \
       vale-3.7.0 \
       xorriso-1.5.6 \
       zig-0.13.0 \
    && dnf clean all
RUN wget -qO- https://github.com/zigtools/zls/releases/download/0.13.0/zls-x86_64-linux.tar.xz | tar -xJ -C /usr/local/bin zls
RUN useradd -m developer
USER developer
