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
    terra-release \ 
    && dnf install -y \ 
       gdb \ 
       limine \
       qemu-system-x86 \
       vale \
       xorriso \
       zig \
    && dnf clean all
RUN useradd -m developer
USER developer
